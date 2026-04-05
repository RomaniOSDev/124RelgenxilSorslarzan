import Combine
import Foundation
import SwiftUI

extension Notification.Name {
    static let navigationProgressDidReset = Notification.Name("navigationProgressDidReset")
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let isUnlocked: (ProgressRepository) -> Bool
}

@MainActor
final class ProgressRepository: ObservableObject {
    private enum Keys {
        static let hasSeenOnboarding = "nav.hasSeenOnboarding"
        static let totalPlaySeconds = "nav.totalPlaySeconds"
        static let totalActivities = "nav.totalActivities"
    }

    private let defaults: UserDefaults

    @Published private(set) var hasSeenOnboarding: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
    }

    func completeOnboarding() {
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
        hasSeenOnboarding = true
        objectWillChange.send()
    }

    var totalPlaySeconds: TimeInterval {
        defaults.double(forKey: Keys.totalPlaySeconds)
    }

    var totalActivitiesCompleted: Int {
        defaults.integer(forKey: Keys.totalActivities)
    }

    private func starsKey(activity: ActivityKind, tier: DifficultyTier, level: Int) -> String {
        "nav.stars.\(activity.rawValue).\(tier.rawValue).\(level)"
    }

    func stars(activity: ActivityKind, tier: DifficultyTier, level: Int) -> Int {
        let v = defaults.integer(forKey: starsKey(activity: activity, tier: tier, level: level))
        return min(3, max(0, v))
    }

    func isLevelUnlocked(activity: ActivityKind, tier: DifficultyTier, level: Int) -> Bool {
        guard level >= 1, level <= LevelsConfig.countPerTier else { return false }
        if level == 1 {
            return isTierEntryUnlocked(activity: activity, tier: tier)
        }
        return stars(activity: activity, tier: tier, level: level - 1) > 0
    }

    private func isTierEntryUnlocked(activity: ActivityKind, tier: DifficultyTier) -> Bool {
        switch tier {
        case .easy:
            return true
        case .normal:
            return (1 ... LevelsConfig.countPerTier).allSatisfy { stars(activity: activity, tier: .easy, level: $0) > 0 }
        case .hard:
            return (1 ... LevelsConfig.countPerTier).allSatisfy { stars(activity: activity, tier: .normal, level: $0) > 0 }
        }
    }

    func recordCompletion(
        activity: ActivityKind,
        tier: DifficultyTier,
        level: Int,
        starsEarned: Int,
        durationSeconds: TimeInterval
    ) {
        let key = starsKey(activity: activity, tier: tier, level: level)
        let current = defaults.integer(forKey: key)
        let merged = min(3, max(current, starsEarned))
        defaults.set(merged, forKey: key)
        defaults.set(totalPlaySeconds + max(0, durationSeconds), forKey: Keys.totalPlaySeconds)
        defaults.set(totalActivitiesCompleted + 1, forKey: Keys.totalActivities)
        objectWillChange.send()
    }

    func totalStars(for activity: ActivityKind) -> Int {
        var sum = 0
        for tier in DifficultyTier.allCases {
            for level in 1 ... LevelsConfig.countPerTier {
                sum += stars(activity: activity, tier: tier, level: level)
            }
        }
        return sum
    }

    func allLevelsCleared(activity: ActivityKind) -> Bool {
        for tier in DifficultyTier.allCases {
            for level in 1 ... LevelsConfig.countPerTier {
                if stars(activity: activity, tier: tier, level: level) < 1 { return false }
            }
        }
        return true
    }

    var achievementDefinitions: [AchievementDefinition] {
        [
            AchievementDefinition(
                id: "first_finish",
                title: "First Finish",
                detail: "Complete any challenge once.",
                isUnlocked: { $0.totalActivitiesCompleted >= 1 }
            ),
            AchievementDefinition(
                id: "star_collector",
                title: "Star Collector",
                detail: "Earn 12 stars across all activities.",
                isUnlocked: { $0.totalStarsAcrossAllActivities() >= 12 }
            ),
            AchievementDefinition(
                id: "route_master",
                title: "Route Specialist",
                detail: "Earn 8 stars in Route Navigator.",
                isUnlocked: { $0.totalStars(for: .routeNavigator) >= 8 }
            ),
            AchievementDefinition(
                id: "landmark_master",
                title: "Landmark Specialist",
                detail: "Earn 8 stars in Landmark Locator.",
                isUnlocked: { $0.totalStars(for: .landmarkLocator) >= 8 }
            ),
            AchievementDefinition(
                id: "compass_master",
                title: "Compass Specialist",
                detail: "Earn 8 stars in Compass Challenge.",
                isUnlocked: { $0.totalStars(for: .compassChallenge) >= 8 }
            ),
            AchievementDefinition(
                id: "dedication",
                title: "Dedicated Explorer",
                detail: "Complete 25 challenges in total.",
                isUnlocked: { $0.totalActivitiesCompleted >= 25 }
            ),
            AchievementDefinition(
                id: "perfection_spark",
                title: "Perfect Spark",
                detail: "Hold at least one three-star result in every activity.",
                isUnlocked: { store in
                    ActivityKind.allCases.allSatisfy { store.hasThreeStarResult(in: $0) }
                }
            )
        ]
    }

    func totalStarsAcrossAllActivities() -> Int {
        ActivityKind.allCases.reduce(0) { partial, activity in
            partial + totalStars(for: activity)
        }
    }

    func hasThreeStarResult(in activity: ActivityKind) -> Bool {
        for tier in DifficultyTier.allCases {
            for level in 1 ... LevelsConfig.countPerTier {
                if stars(activity: activity, tier: tier, level: level) >= 3 {
                    return true
                }
            }
        }
        return false
    }

    func unlockedAchievementIDs() -> Set<String> {
        Set(unlockedAchievements().map(\.id))
    }

    func unlockedAchievements() -> [AchievementDefinition] {
        achievementDefinitions.filter { $0.isUnlocked(self) }
    }

    func firstNewlyUnlockedAchievement(comparedTo previousIDs: Set<String>) -> AchievementDefinition? {
        unlockedAchievements().first { !previousIDs.contains($0.id) }
    }

    func resetAllProgress() {
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix("nav.") }
        keys.forEach { defaults.removeObject(forKey: $0) }
        hasSeenOnboarding = false
        objectWillChange.send()
        NotificationCenter.default.post(name: .navigationProgressDidReset, object: nil)
    }
}
