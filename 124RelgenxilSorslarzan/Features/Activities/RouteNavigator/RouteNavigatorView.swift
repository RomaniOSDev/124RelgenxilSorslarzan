import MapKit
import SwiftUI

struct RouteNavigatorView: View {
    @EnvironmentObject private var progress: ProgressRepository
    @StateObject private var viewModel: RouteNavigatorViewModel
    @Binding var path: [ChallengeNavDestination]

    @State private var mapSize: CGSize = .init(width: 320, height: 320)
    @State private var dragStartBase: CLLocationCoordinate2D?
    @State private var dragEndBase: CLLocationCoordinate2D?

    private let activity: ActivityKind = .routeNavigator

    init(tier: DifficultyTier, level: Int, path: Binding<[ChallengeNavDestination]>) {
        _viewModel = StateObject(wrappedValue: RouteNavigatorViewModel(tier: tier, level: level))
        _path = path
    }

    private var tier: DifficultyTier { viewModel.tier }
    private var level: Int { viewModel.level }

    private var mapAnnotations: [RouteMapAnnotation] {
        var list: [RouteMapAnnotation] = []
        for (index, center) in viewModel.obstacleCenters.enumerated() {
            list.append(RouteMapAnnotation(id: "obs-\(index)", coordinate: center, role: .obstacle(index)))
        }
        list.append(RouteMapAnnotation(id: "start", coordinate: viewModel.startCoordinate, role: .start))
        list.append(RouteMapAnnotation(id: "end", coordinate: viewModel.endCoordinate, role: .end))
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                mapSection
                controls
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .appScreenBackdrop()
        .onAppear {
            viewModel.startClock()
        }
        .onDisappear {
            viewModel.stopClock()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Route Navigator")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .appTitleDepth()
            Text("Drag the pins, generate options, then pick the safest shortest path.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Text("Elapsed")
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text(formattedTime(viewModel.elapsed))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.appPrimary)
                    .appButtonLabel()
            }
            .padding(12)
            .appElevatedCard(cornerRadius: 12)
        }
    }

    private var mapSection: some View {
        Map(coordinateRegion: $viewModel.region, interactionModes: [.pan, .zoom], showsUserLocation: false, annotationItems: mapAnnotations) { item in
            MapAnnotation(coordinate: item.coordinate) {
                annotationBody(item)
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppChrome.cardRim, lineWidth: 1)
        )
        .appCardShadowElevated()
        .overlay(
            GeometryReader { geo in
                Color.clear
                    .onAppear { mapSize = geo.size }
                    .onChange(of: geo.size) { newValue in
                        mapSize = newValue
                    }
            }
        )
    }

    private var obstacleDotSize: CGFloat {
        switch viewModel.tier {
        case .easy: return 46
        case .normal: return 52
        case .hard: return 58
        }
    }

    @ViewBuilder
    private func annotationBody(_ item: RouteMapAnnotation) -> some View {
        switch item.role {
        case .obstacle(_):
            Circle()
                .fill(Color.appPrimary.opacity(0.22))
                .frame(width: obstacleDotSize, height: obstacleDotSize)
                .allowsHitTesting(false)
        case .start:
            VStack(spacing: 4) {
                Text("Start")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.appSurface.opacity(0.92))
                    .clipShape(Capsule())
                Circle()
                    .fill(Color.appAccent)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard viewModel.phase == .adjustingPins else { return }
                                if dragStartBase == nil { dragStartBase = viewModel.startCoordinate }
                                if let base = dragStartBase {
                                    viewModel.startCoordinate = offsetCoordinate(
                                        base: base,
                                        translation: value.translation,
                                        mapSize: mapSize,
                                        region: viewModel.region
                                    )
                                }
                            }
                            .onEnded { _ in
                                dragStartBase = nil
                            }
                    )
            }
        case .end:
            VStack(spacing: 4) {
                Text("End")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.appBackground)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.appSurface.opacity(0.92))
                    .clipShape(Capsule())
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard viewModel.phase == .adjustingPins else { return }
                                if dragEndBase == nil { dragEndBase = viewModel.endCoordinate }
                                if let base = dragEndBase {
                                    viewModel.endCoordinate = offsetCoordinate(
                                        base: base,
                                        translation: value.translation,
                                        mapSize: mapSize,
                                        region: viewModel.region
                                    )
                                }
                            }
                            .onEnded { _ in
                                dragEndBase = nil
                            }
                    )
            }
        }
    }

    private func offsetCoordinate(
        base: CLLocationCoordinate2D,
        translation: CGSize,
        mapSize: CGSize,
        region: MKCoordinateRegion
    ) -> CLLocationCoordinate2D {
        let latDelta = -translation.height * region.span.latitudeDelta / max(mapSize.height, 1)
        let lonDelta = translation.width * region.span.longitudeDelta / max(mapSize.width, 1)
        return CLLocationCoordinate2D(latitude: base.latitude + latDelta, longitude: base.longitude + lonDelta)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if viewModel.phase == .adjustingPins {
                Button {
                    viewModel.prepareRoutes()
                } label: {
                    Text("Generate route options")
                        .appButtonLabel()
                }
                .buttonStyle(AppPrimaryButtonStyle())
            } else {
                Text("Pick the route that avoids obstacles with the shortest distance when possible.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(viewModel.routeOptions) { option in
                    Button {
                        viewModel.selectedRouteID = option.id
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(option.caption)
                                    .font(.headline)
                                    .foregroundStyle(Color.appTextPrimary)
                                    .appButtonLabel()
                                Spacer()
                                if viewModel.selectedRouteID == option.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.appPrimary)
                                }
                            }
                            RouteSchematic(points: option.schematicPoints, highlight: option.intersectsObstacle)
                                .frame(height: 90)
                            HStack {
                                Text(option.intersectsObstacle ? "Crosses hazard" : "Clear of hazards")
                                    .font(.caption)
                                    .foregroundStyle(option.intersectsObstacle ? Color.appTextSecondary : Color.appAccent)
                                Spacer()
                                Text("\(Int(option.distance)) m")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.appTextSecondary)
                                    .appButtonLabel()
                            }
                        }
                        .padding(12)
                        .background {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppChrome.surfaceCard)
                                    .opacity(viewModel.selectedRouteID == option.id ? 1 : 0.78)
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(AppChrome.cardSheen)
                                    .opacity(viewModel.selectedRouteID == option.id ? 1 : 0.6)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.appAccent.opacity(viewModel.selectedRouteID == option.id ? 0.95 : 0.2),
                                            Color.appPrimary.opacity(viewModel.selectedRouteID == option.id ? 0.35 : 0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: viewModel.selectedRouteID == option.id ? 2 : 1
                                )
                        )
                        .appCardShadowSoft()
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    submit()
                } label: {
                    Text("Submit selection")
                        .appButtonLabel()
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .disabled(viewModel.selectedRouteID == nil)

                Button {
                    viewModel.phase = .adjustingPins
                    viewModel.routeOptions = []
                    viewModel.selectedRouteID = nil
                } label: {
                    Text("Adjust pins again")
                        .appButtonLabel()
                }
                .buttonStyle(AppSecondaryButtonStyle())
            }
        }
    }

    private func submit() {
        let result = viewModel.evaluateSelection()
        viewModel.stopClock()
        ChallengeCompletion.finish(
            progress: progress,
            path: $path,
            activity: activity,
            tier: tier,
            level: level,
            stars: result.stars,
            duration: viewModel.elapsed,
            accuracyPercent: result.accuracy
        )
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct RouteMapAnnotation: Identifiable {
    enum Role {
        case start
        case end
        case obstacle(Int)
    }

    let id: String
    let coordinate: CLLocationCoordinate2D
    let role: Role
}

private struct RouteSchematic: View {
    let points: [CGPoint]
    let highlight: Bool

    var body: some View {
        Canvas { context, size in
            guard points.count > 1 else { return }
            var path = Path()
            let scaled = points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
            path.addLines(scaled)
            context.stroke(
                path,
                with: .color(highlight ? Color.appTextSecondary.opacity(0.55) : Color.appAccent),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            for point in scaled {
                let rect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: rect), with: .color(Color.appPrimary))
            }
        }
        .background(
            LinearGradient(
                colors: [Color.appBackground.opacity(0.55), Color.appSurface.opacity(0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.appAccent.opacity(0.15), lineWidth: 1)
        )
    }
}
