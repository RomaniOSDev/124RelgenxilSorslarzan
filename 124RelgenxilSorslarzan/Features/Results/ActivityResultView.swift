import SwiftUI

struct ActivityResultView: View {
    @EnvironmentObject private var progress: ProgressRepository
    let outcome: ActivityOutcome
    @Binding var path: [ChallengeNavDestination]

    @State private var visibleStars = 0
    @State private var showBanner = false

    private var achievementTitle: String? {
        guard let id = outcome.achievementUnlockedID else { return nil }
        return progress.achievementDefinitions.first { $0.id == id }?.title
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Results")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appTitleDepth()

                    HStack(spacing: 14) {
                        ForEach(0 ..< 3, id: \.self) { index in
                            StarGlyphView(filled: index < visibleStars)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.appPrimary.opacity(index < visibleStars ? 0.55 : 0), radius: 12, y: 4)
                                .scaleEffect(index < visibleStars ? 1 : 0.6)
                                .animation(AppMotion.spring.delay(Double(index) * 0.15), value: visibleStars)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    VStack(spacing: 10) {
                        metricRow(title: "Time", value: formattedDuration(outcome.durationSeconds))
                        metricRow(title: "Accuracy", value: "\(outcome.accuracyPercent)%")
                        metricRow(title: "Stars earned", value: "\(outcome.stars)/3")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appElevatedCard(cornerRadius: 16)

                    VStack(spacing: 12) {
                        if let next = nextPlay {
                            Button {
                                path.removeLast()
                                path.append(next)
                            } label: {
                                Text("Next Level")
                                    .appButtonLabel()
                            }
                            .buttonStyle(AppPrimaryButtonStyle())
                        }

                        Button {
                            path.removeLast()
                            path.append(.play(outcome.activity, outcome.tier, outcome.level))
                        } label: {
                            Text("Retry")
                                .appButtonLabel()
                        }
                        .buttonStyle(AppSecondaryButtonStyle())

                        Button {
                            path.removeLast()
                        } label: {
                            Text("Back to Levels")
                                .appButtonLabel()
                        }
                        .buttonStyle(AppSecondaryButtonStyle())
                    }
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.top, achievementTitle == nil ? 0 : 54)
            }
            .scrollIndicators(.hidden)
            .appScreenBackdrop()

            if let title = achievementTitle, showBanner {
                achievementBanner(title: title)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(AppMotion.ease, value: showBanner)
            }
        }
        .onAppear {
            animateStars()
            if achievementTitle != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(AppMotion.ease) {
                        showBanner = true
                    }
                }
            }
        }
    }

    private var nextPlay: ChallengeNavDestination? {
        guard outcome.level < LevelsConfig.countPerTier else { return nil }
        let nextLevel = outcome.level + 1
        guard progress.isLevelUnlocked(activity: outcome.activity, tier: outcome.tier, level: nextLevel) else {
            return nil
        }
        return .play(outcome.activity, outcome.tier, nextLevel)
    }

    private func animateStars() {
        visibleStars = 0
        let target = outcome.stars
        for step in 1 ... target {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step - 1) * 0.15) {
                withAnimation(AppMotion.spring) {
                    visibleStars = step
                }
            }
        }
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .appButtonLabel()
        }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private func achievementBanner(title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.appBackground)
            Text("Achievement unlocked: \(title)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appBackground)
                .appButtonLabel()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppChrome.primaryButtonFill)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appTextPrimary.opacity(0.2), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.appTextPrimary.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.appPrimary.opacity(0.45), radius: 12, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}
