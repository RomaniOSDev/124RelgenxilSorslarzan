import SwiftUI

struct ChallengeHubView: View {
    @EnvironmentObject private var progress: ProgressRepository
    @State private var path: [ChallengeNavDestination] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollScreen(title: "Challenges") {
                VStack(spacing: 14) {
                    ForEach(ActivityKind.allCases, id: \.self) { activity in
                        Button {
                            path.append(.levelPicker(activity))
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                ActivityGlyphView(activity: activity)
                                    .frame(width: 52, height: 52)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(activity.displayTitle)
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.85)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(activity.summary)
                                        .font(.footnote)
                                        .foregroundStyle(Color.appTextSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    StarRowView(
                                        value: min(12, progress.totalStars(for: activity)),
                                        maxValue: 12,
                                        starDimension: 14,
                                        starSpacing: 3
                                    )
                                }
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.appAccent)
                                    .frame(width: 20, alignment: .center)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .appElevatedCard(cornerRadius: 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationDestination(for: ChallengeNavDestination.self) { destination in
                switch destination {
                case let .levelPicker(kind):
                    LevelGridView(activity: kind, path: $path)
                case let .play(kind, tier, level):
                    playSurface(kind: kind, tier: tier, level: level)
                case let .result(outcome):
                    ActivityResultView(outcome: outcome, path: $path)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: .navigationProgressDidReset)) { _ in
            path.removeAll()
        }
    }

    @ViewBuilder
    private func playSurface(kind: ActivityKind, tier: DifficultyTier, level: Int) -> some View {
        switch kind {
        case .routeNavigator:
            RouteNavigatorView(tier: tier, level: level, path: $path)
        case .landmarkLocator:
            LandmarkLocatorView(tier: tier, level: level, path: $path)
        case .compassChallenge:
            CompassChallengeView(tier: tier, level: level, path: $path)
        }
    }
}
