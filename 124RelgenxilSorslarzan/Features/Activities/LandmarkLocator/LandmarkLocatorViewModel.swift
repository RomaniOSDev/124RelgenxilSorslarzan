import Combine
import CoreLocation
import Foundation
import MapKit

@MainActor
final class LandmarkLocatorViewModel: ObservableObject {
    let tier: DifficultyTier
    let level: Int

    @Published var region: MKCoordinateRegion
    @Published var targetCoordinate: CLLocationCoordinate2D
    @Published var guessCoordinate: CLLocationCoordinate2D?
    @Published var elapsed: TimeInterval = 0

    let clueTitle: String
    let clueBody: String
    let obscurity: Double

    private var timerCancellable: AnyCancellable?
    private var startedAt: Date?
    private let toleranceMeters: Double

    init(tier: DifficultyTier, level: Int) {
        self.tier = tier
        self.level = level
        var generator = SeededGenerator(seed: LandmarkLocatorViewModel.seed(tier: tier, level: level))
        let spanBase: Double = switch tier {
        case .easy: 0.06
        case .normal: 0.08
        case .hard: 0.1
        }
        let span = spanBase + Double(level) * 0.006
        let centerLat = 48.8566 + generator.nextFractionSigned() * 0.04
        let centerLon = 2.3522 + generator.nextFractionSigned() * 0.04
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
        self.targetCoordinate = CLLocationCoordinate2D(
            latitude: centerLat + generator.nextFractionSigned() * span * 0.35,
            longitude: centerLon + generator.nextFractionSigned() * span * 0.35
        )
        self.clueTitle = LandmarkLocatorViewModel.title(for: level)
        self.clueBody = LandmarkLocatorViewModel.body(for: tier, level: level, generator: &generator)
        self.obscurity = switch tier {
        case .easy: 0.15
        case .normal: 0.35
        case .hard: 0.55
        }
        self.toleranceMeters = switch tier {
        case .easy: 220
        case .normal: 160
        case .hard: 110
        }
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

    func coordinate(from point: CGPoint, mapSize: CGSize) -> CLLocationCoordinate2D {
        let xFrac = point.x / max(mapSize.width, 1)
        let yFrac = point.y / max(mapSize.height, 1)
        let lon = region.center.longitude + (xFrac - 0.5) * region.span.longitudeDelta
        let lat = region.center.latitude - (yFrac - 0.5) * region.span.latitudeDelta
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    func evaluateGuess() -> (stars: Int, accuracy: Int) {
        guard let guess = guessCoordinate else {
            return (0, 0)
        }
        let distance = haversineMeters(guess, targetCoordinate)
        let ratio = distance / max(toleranceMeters, 1)
        let accuracy = max(0, min(100, Int(100 - ratio * 55)))
        let timeLimit: TimeInterval = switch tier {
        case .easy: 95
        case .normal: 80
        case .hard: 65
        }
        if distance <= toleranceMeters {
            if ratio <= 0.45 && elapsed <= timeLimit {
                return (3, max(accuracy, 94))
            }
            if ratio <= 0.75 {
                return (2, max(accuracy, 82))
            }
            return (1, max(accuracy, 70))
        }
        if distance <= toleranceMeters * 1.9 {
            return (1, max(40, accuracy))
        }
        return (0, accuracy)
    }

    private func haversineMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let r = 6_371_000.0
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * r * asin(min(1, sqrt(h)))
    }

    private static func seed(tier: DifficultyTier, level: Int) -> UInt64 {
        var hasher = Hasher()
        hasher.combine("landmark")
        hasher.combine(tier.rawValue)
        hasher.combine(level)
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }

    private static func title(for level: Int) -> String {
        let options = [
            "Riverside plaza",
            "Historic crossing",
            "Old quarter gate",
            "Harbor viewpoint"
        ]
        return options[level % options.count]
    }

    private static func body(for tier: DifficultyTier, level: Int, generator: inout SeededGenerator) -> String {
        let distanceHint = 400 + (level * 120) + Int(generator.next() % 180)
        switch tier {
        case .easy:
            return "The place sits near a gentle bend of the river, about \(distanceHint) meters from the marked green belt on the map."
        case .normal:
            return "Look for a diagonal avenue meeting a curved shoreline; the target hides one short block inland from that curve."
        case .hard:
            return "Trace the narrow lanes north of the rail arc—your mark aligns with the third offset courtyard from the junction."
        }
    }
}

private struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xC0FFEE_BEE5 : seed
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
