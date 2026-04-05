import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class RouteNavigatorViewModel: ObservableObject {
    enum Phase: Equatable {
        case adjustingPins
        case choosingRoute
    }

    struct RouteOption: Identifiable, Hashable {
        let id: UUID
        let caption: String
        let distance: Double
        let intersectsObstacle: Bool
        let schematicPoints: [CGPoint]
    }

    let tier: DifficultyTier
    let level: Int

    @Published var region: MKCoordinateRegion
    @Published var startCoordinate: CLLocationCoordinate2D
    @Published var endCoordinate: CLLocationCoordinate2D
    @Published var obstacleCenters: [CLLocationCoordinate2D]
    @Published var phase: Phase = .adjustingPins
    @Published var routeOptions: [RouteOption] = []
    @Published var selectedRouteID: UUID?
    @Published var elapsed: TimeInterval = 0

    private var timerCancellable: AnyCancellable?
    private var startedAt: Date?
    private let obstacleRadiusDegrees: Double

    init(tier: DifficultyTier, level: Int) {
        self.tier = tier
        self.level = level
        var generator = SeededGenerator(seed: Self.seed(tier: tier, level: level))
        let baseLat = 37.7749 + generator.nextFractionSigned() * 0.02
        let baseLon = -122.4194 + generator.nextFractionSigned() * 0.02
        let spanFactor: Double = switch tier {
        case .easy: 0.035
        case .normal: 0.048
        case .hard: 0.06
        }
        let span = spanFactor + Double(level) * 0.004
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: baseLat, longitude: baseLon),
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
        self.startCoordinate = CLLocationCoordinate2D(
            latitude: baseLat - span * 0.25,
            longitude: baseLon - span * 0.2
        )
        self.endCoordinate = CLLocationCoordinate2D(
            latitude: baseLat + span * 0.25,
            longitude: baseLon + span * 0.22
        )
        let obstacleCount = (tier == .easy ? 2 : tier == .normal ? 3 : 4) + (level / 2)
        var obstacles: [CLLocationCoordinate2D] = []
        for _ in 0 ..< obstacleCount {
            let lat = baseLat + generator.nextFractionSigned() * span * 0.45
            let lon = baseLon + generator.nextFractionSigned() * span * 0.55
            obstacles.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        self.obstacleCenters = obstacles
        self.obstacleRadiusDegrees = 0.0014 * Double(level) + (tier == .hard ? 0.0016 : tier == .normal ? 0.0011 : 0.0008)
    }

    func startClock() {
        guard startedAt == nil else { return }
        startedAt = Date()
        timerCancellable = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let startedAt = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(startedAt)
            }
    }

    func stopClock() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func prepareRoutes() {
        let starts = startCoordinate
        let ends = endCoordinate
        let midLat = (starts.latitude + ends.latitude) / 2
        let midLon = (starts.longitude + ends.longitude) / 2
        let dx = ends.longitude - starts.longitude
        let dy = ends.latitude - starts.latitude
        let length = max(1e-6, sqrt(dx * dx + dy * dy))
        let perpLat = -dx / length * 0.18 * region.span.latitudeDelta
        let perpLon = dy / length * 0.18 * region.span.longitudeDelta

        let waypointA = CLLocationCoordinate2D(latitude: midLat + perpLat, longitude: midLon + perpLon)
        let waypointB = CLLocationCoordinate2D(latitude: midLat - perpLat, longitude: midLon - perpLon)

        let directHits = segmentCollides(starts, ends)
        let viaAHits = segmentCollides(starts, waypointA) || segmentCollides(waypointA, ends)
        let viaBHits = segmentCollides(starts, waypointB) || segmentCollides(waypointB, ends)

        let dDirect = haversine(starts, ends)
        let dA = haversine(starts, waypointA) + haversine(waypointA, ends)
        let dB = haversine(starts, waypointB) + haversine(waypointB, ends)

        let options: [RouteOption] = [
            RouteOption(
                id: UUID(),
                caption: "Direct corridor",
                distance: dDirect,
                intersectsObstacle: directHits,
                schematicPoints: normalizedPolyline([starts, ends])
            ),
            RouteOption(
                id: UUID(),
                caption: "Northern bend",
                distance: dA,
                intersectsObstacle: viaAHits,
                schematicPoints: normalizedPolyline([starts, waypointA, ends])
            ),
            RouteOption(
                id: UUID(),
                caption: "Southern bend",
                distance: dB,
                intersectsObstacle: viaBHits,
                schematicPoints: normalizedPolyline([starts, waypointB, ends])
            )
        ]

        routeOptions = options.shuffled(seed: Self.seed(tier: tier, level: level))
        phase = .choosingRoute
        selectedRouteID = nil
    }

    func evaluateSelection() -> (stars: Int, accuracy: Int) {
        guard let pick = selectedRouteID, let chosen = routeOptions.first(where: { $0.id == pick }) else {
            return (0, 0)
        }
        let hasClean = routeOptions.contains { !$0.intersectsObstacle }
        let bestChoice = optimalOption()
        let timeLimit = timeThreshold()

        if hasClean {
            if chosen.intersectsObstacle {
                return (0, 30)
            }
            if let bestChoice, chosen.id == bestChoice.id {
                let stars = elapsed <= timeLimit ? 3 : 2
                let accuracy = elapsed <= timeLimit ? 98 : 90
                return (stars, accuracy)
            }
            return (1, 68)
        }
        if let bestChoice, chosen.id == bestChoice.id {
            let stars = elapsed <= timeLimit ? 3 : 2
            return (stars, 92)
        }
        let margin: Double = 120
        let baseline = bestChoice?.distance ?? chosen.distance
        let ok = chosen.distance <= baseline + margin
        return ok ? (1, 60) : (0, 35)
    }

    func coordinate(from point: CGPoint, mapSize: CGSize) -> CLLocationCoordinate2D {
        let xFrac = point.x / max(mapSize.width, 1)
        let yFrac = point.y / max(mapSize.height, 1)
        let lon = region.center.longitude + (xFrac - 0.5) * region.span.longitudeDelta
        let lat = region.center.latitude - (yFrac - 0.5) * region.span.latitudeDelta
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private func optimalOption() -> RouteOption? {
        let clean = routeOptions.filter { !$0.intersectsObstacle }
        if let best = clean.min(by: { $0.distance < $1.distance }) {
            return best
        }
        return routeOptions.min(by: { $0.distance < $1.distance })
    }

    private func timeThreshold() -> TimeInterval {
        switch tier {
        case .easy: return 85
        case .normal: return 70
        case .hard: return 55
        }
    }

    private func segmentCollides(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        obstacleCenters.contains { obstacle in
            distancePointToSegmentDegrees(
                px: obstacle.latitude,
                py: obstacle.longitude,
                ax: a.latitude,
                ay: a.longitude,
                bx: b.latitude,
                by: b.longitude
            ) < obstacleRadiusDegrees
        }
    }

    private func normalizedPolyline(_ coords: [CLLocationCoordinate2D]) -> [CGPoint] {
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(), let minLon = lons.min(), let maxLon = lons.max() else {
            return []
        }
        let dLat = max(maxLat - minLat, 1e-6)
        let dLon = max(maxLon - minLon, 1e-6)
        return coords.map { coord in
            CGPoint(
                x: (coord.longitude - minLon) / dLon,
                y: 1 - (coord.latitude - minLat) / dLat
            )
        }
    }

    private func haversine(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let r = 6_371_000.0
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * r * asin(min(1, sqrt(h)))
    }

    private func distancePointToSegmentDegrees(px: Double, py: Double, ax: Double, ay: Double, bx: Double, by: Double) -> Double {
        let abx = bx - ax
        let aby = by - ay
        let apx = px - ax
        let apy = py - ay
        let abLen2 = abx * abx + aby * aby
        if abLen2 < 1e-12 {
            return hypot(px - ax, py - ay)
        }
        var t = (apx * abx + apy * aby) / abLen2
        t = min(1, max(0, t))
        let cx = ax + abx * t
        let cy = ay + aby * t
        return hypot(px - cx, py - cy)
    }

    private static func seed(tier: DifficultyTier, level: Int) -> UInt64 {
        var hasher = Hasher()
        hasher.combine(tier.rawValue)
        hasher.combine(level)
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }
}

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &*= 6364136223846793005
        state &+= 1442695040888963407
        return state
    }

    mutating func nextFractionSigned() -> Double {
        let value = Double(next() % 10_000) / 10_000.0
        return (value - 0.5) * 2
    }
}

private extension Array where Element == RouteNavigatorViewModel.RouteOption {
    func shuffled(seed: UInt64) -> [Element] {
        var copy = self
        var gen = SeededGenerator(seed: seed &+ 31)
        guard copy.count > 1 else { return copy }
        for i in stride(from: copy.count - 1, through: 1, by: -1) {
            let j = Int(gen.next() % UInt64(i + 1))
            copy.swapAt(i, j)
        }
        return copy
    }
}
