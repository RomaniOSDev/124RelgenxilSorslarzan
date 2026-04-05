import MapKit
import SwiftUI

struct LandmarkLocatorView: View {
    @EnvironmentObject private var progress: ProgressRepository
    @StateObject private var viewModel: LandmarkLocatorViewModel
    @Binding var path: [ChallengeNavDestination]

    private let activity: ActivityKind = .landmarkLocator

    init(tier: DifficultyTier, level: Int, path: Binding<[ChallengeNavDestination]>) {
        _viewModel = StateObject(wrappedValue: LandmarkLocatorViewModel(tier: tier, level: level))
        _path = path
    }

    private var tier: DifficultyTier { viewModel.tier }
    private var level: Int { viewModel.level }

    private var mapAnnotations: [LandmarkMapItem] {
        var items: [LandmarkMapItem] = []
        if let guess = viewModel.guessCoordinate {
            items.append(LandmarkMapItem(id: "guess", coordinate: guess, role: .guess))
        }
        return items
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    mapPanel
                        .frame(maxWidth: .infinity, alignment: .leading)
                    cluePanel
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 16) {
                    mapPanel
                    cluePanel
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .appScreenBackdrop()
        .onAppear { viewModel.startClock() }
        .onDisappear { viewModel.stopClock() }
    }

    private var mapPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Map")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            ZStack {
                Map(coordinateRegion: $viewModel.region, interactionModes: [.pan, .zoom], showsUserLocation: false, annotationItems: mapAnnotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        Circle()
                            .strokeBorder(Color.appPrimary, lineWidth: 3)
                            .background(Circle().fill(Color.appAccent.opacity(0.35)))
                            .frame(width: 26, height: 26)
                    }
                }
                .frame(minHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppChrome.cardRim, lineWidth: 1)
                )
                .appCardShadowElevated()

                ReticleOverlay()
                    .allowsHitTesting(false)
            }
            Button {
                viewModel.guessCoordinate = viewModel.region.center
            } label: {
                Text("Place marker at map center")
                    .appButtonLabel()
            }
            .buttonStyle(AppSecondaryButtonStyle())

            nudgePad

            Text("Pan and zoom the map freely, align the crosshair, then place or nudge your marker.")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nudgePad: some View {
        let lat = viewModel.region.span.latitudeDelta * 0.035
        let lon = viewModel.region.span.longitudeDelta * 0.035
        return VStack(spacing: 8) {
            Button {
                shiftGuess(lat: lat, lon: 0)
            } label: {
                Text("Nudge north")
                    .appButtonLabel()
            }
            .buttonStyle(AppSecondaryButtonStyle())
            HStack(spacing: 8) {
                Button {
                    shiftGuess(lat: 0, lon: -lon)
                } label: {
                    Text("West")
                        .appButtonLabel()
                }
                .buttonStyle(AppSecondaryButtonStyle())
                Button {
                    shiftGuess(lat: 0, lon: lon)
                } label: {
                    Text("East")
                        .appButtonLabel()
                }
                .buttonStyle(AppSecondaryButtonStyle())
            }
            Button {
                shiftGuess(lat: -lat, lon: 0)
            } label: {
                Text("Nudge south")
                    .appButtonLabel()
            }
            .buttonStyle(AppSecondaryButtonStyle())
        }
    }

    private func shiftGuess(lat: Double, lon: Double) {
        let base = viewModel.guessCoordinate ?? viewModel.region.center
        let next = CLLocationCoordinate2D(latitude: base.latitude + lat, longitude: base.longitude + lon)
        viewModel.guessCoordinate = next
    }

    private var cluePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Landmark Locator")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .appTitleDepth()
            Text("Use the silhouette and the hints, then mark the map.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            LandmarkSilhouetteCanvas(obscurity: viewModel.obscurity, level: level)
                .frame(height: 160)
                .padding(6)
                .appElevatedCard(cornerRadius: 16)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.clueTitle)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Text(viewModel.clueBody)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appElevatedCard(cornerRadius: 14)

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
            .appInsetPlate(cornerRadius: 12)

            Button {
                submit()
            } label: {
                Text("Submit marker")
                    .appButtonLabel()
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .disabled(viewModel.guessCoordinate == nil)

            Button {
                viewModel.guessCoordinate = nil
            } label: {
                Text("Clear marker")
                    .appButtonLabel()
            }
            .buttonStyle(AppSecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func submit() {
        let outcome = viewModel.evaluateGuess()
        viewModel.stopClock()
        ChallengeCompletion.finish(
            progress: progress,
            path: $path,
            activity: activity,
            tier: tier,
            level: level,
            stars: outcome.stars,
            duration: viewModel.elapsed,
            accuracyPercent: outcome.accuracy
        )
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct LandmarkMapItem: Identifiable {
    enum Role { case guess }

    let id: String
    let coordinate: CLLocationCoordinate2D
    let role: Role
}

private struct ReticleOverlay: View {
    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(Color.appAccent.opacity(0.65), lineWidth: 1)
                .frame(width: 120, height: 120)
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 6)
        }
    }
}

private struct LandmarkSilhouetteCanvas: View {
    let obscurity: Double
    let level: Int

    var body: some View {
        Canvas { context, size in
            let base = CGRect(x: size.width * 0.18, y: size.height * 0.2, width: size.width * 0.64, height: size.height * 0.62)
            var building = Path(roundedRect: base, cornerRadius: 10)
            context.fill(building, with: .color(Color.appAccent.opacity(0.55)))
            context.stroke(building, with: .color(Color.appPrimary.opacity(0.85)), lineWidth: 2)

            let dome = Path(ellipseIn: CGRect(x: base.midX - 22, y: base.minY - 18, width: 44, height: 36))
            context.fill(dome, with: .color(Color.appTextSecondary.opacity(0.55)))

            let spire = Path { path in
                path.move(to: CGPoint(x: base.maxX - 18, y: base.maxY))
                path.addLine(to: CGPoint(x: base.maxX - 4, y: base.minY - 26))
                path.addLine(to: CGPoint(x: base.maxX - 30, y: base.maxY))
            }
            context.fill(spire, with: .color(Color.appPrimary.opacity(0.75)))

            let coverHeight = CGFloat(obscurity) * size.height * 0.55
            var cover = Path()
            cover.addRect(CGRect(x: 0, y: 0, width: size.width, height: coverHeight))
            context.fill(cover, with: .color(Color.appBackground.opacity(0.92)))

            if level % 2 == 0 {
                var diag = Path()
                diag.move(to: CGPoint(x: 0, y: size.height))
                diag.addLine(to: CGPoint(x: size.width, y: size.height * 0.25))
                context.stroke(diag, with: .color(Color.appSurface.opacity(0.9)), style: StrokeStyle(lineWidth: 14, lineCap: .round))
            }
        }
    }
}
