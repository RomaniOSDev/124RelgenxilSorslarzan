import Foundation

enum ActivityKind: String, CaseIterable, Codable, Hashable {
    case routeNavigator
    case landmarkLocator
    case compassChallenge

    var displayTitle: String {
        switch self {
        case .routeNavigator: return "Route Navigator"
        case .landmarkLocator: return "Landmark Locator"
        case .compassChallenge: return "Compass Challenge"
        }
    }

    var summary: String {
        switch self {
        case .routeNavigator:
            return "Plot efficient paths and pick the best route around obstacles."
        case .landmarkLocator:
            return "Use clues and the map to mark the right spot."
        case .compassChallenge:
            return "Follow directional cues step by step to reach the target."
        }
    }
}

enum DifficultyTier: String, CaseIterable, Codable, Hashable {
    case easy
    case normal
    case hard

    var displayTitle: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

enum ChallengeNavDestination: Hashable {
    case levelPicker(ActivityKind)
    case play(ActivityKind, DifficultyTier, Int)
    case result(ActivityOutcome)
}

struct ActivityOutcome: Hashable {
    let activity: ActivityKind
    let tier: DifficultyTier
    let level: Int
    let stars: Int
    let durationSeconds: TimeInterval
    let accuracyPercent: Int
    let achievementUnlockedID: String?
}

enum LevelsConfig {
    static let countPerTier = 4
}
