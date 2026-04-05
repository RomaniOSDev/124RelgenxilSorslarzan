import SwiftUI

enum ChallengeCompletion {
    @MainActor
    static func finish(
        progress: ProgressRepository,
        path: Binding<[ChallengeNavDestination]>,
        activity: ActivityKind,
        tier: DifficultyTier,
        level: Int,
        stars: Int,
        duration: TimeInterval,
        accuracyPercent: Int
    ) {
        let prior = progress.unlockedAchievementIDs()
        progress.recordCompletion(
            activity: activity,
            tier: tier,
            level: level,
            starsEarned: stars,
            durationSeconds: duration
        )
        let unlocked = progress.firstNewlyUnlockedAchievement(comparedTo: prior)
        let outcome = ActivityOutcome(
            activity: activity,
            tier: tier,
            level: level,
            stars: stars,
            durationSeconds: duration,
            accuracyPercent: accuracyPercent,
            achievementUnlockedID: unlocked?.id
        )
        if !path.wrappedValue.isEmpty {
            path.wrappedValue.removeLast()
        }
        path.wrappedValue.append(.result(outcome))
    }
}
