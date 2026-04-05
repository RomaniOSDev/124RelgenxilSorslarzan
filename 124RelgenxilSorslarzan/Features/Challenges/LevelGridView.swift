import SwiftUI

struct LevelGridView: View {
    @EnvironmentObject private var progress: ProgressRepository
    let activity: ActivityKind
    @Binding var path: [ChallengeNavDestination]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text(activity.displayTitle)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
                Text(activity.summary)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(DifficultyTier.allCases, id: \.self) { tier in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            Text(tier.displayTitle)
                                .font(.headline)
                                .foregroundStyle(Color.appTextPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                            Text(tierSubtitle(tier))
                                .font(.caption)
                                .foregroundStyle(Color.appTextSecondary)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(2)
                                .minimumScaleFactor(0.75)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(1 ... LevelsConfig.countPerTier, id: \.self) { level in
                                levelCell(tier: tier, level: level)
                            }
                        }
                    }
                    .padding(14)
                    .appElevatedCard(cornerRadius: 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .clipped()
        .appScreenBackdrop()
    }

    private func tierSubtitle(_ tier: DifficultyTier) -> String {
        switch tier {
        case .easy: return "Straightforward layouts"
        case .normal: return "Adds detours and noise"
        case .hard: return "Tight timing and precision"
        }
    }

    @ViewBuilder
    private func levelCell(tier: DifficultyTier, level: Int) -> some View {
        let unlocked = progress.isLevelUnlocked(activity: activity, tier: tier, level: level)
        let stars = progress.stars(activity: activity, tier: tier, level: level)
        Button {
            guard unlocked else { return }
            path.append(.play(activity, tier, level))
        } label: {
            VStack(spacing: 6) {
                if unlocked {
                    Text("\(level)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                    StarRowView(value: stars, maxValue: 3, starDimension: 16, starSpacing: 3)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.headline)
                        .foregroundStyle(Color.appTextSecondary)
                    Text("Locked")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .appButtonLabel()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 72)
            .padding(.vertical, 6)
            .appLevelCellChrome(unlocked: unlocked, cornerRadius: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Level \(level) \(tier.displayTitle)")
        .disabled(!unlocked)
    }
}
