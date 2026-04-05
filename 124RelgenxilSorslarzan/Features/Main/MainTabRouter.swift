import Combine
import SwiftUI

@MainActor
final class MainTabRouter: ObservableObject {
    @Published var selectedTab: Int = 0

    static let homeTab = 0
    static let challengesTab = 1
    static let profileTab = 2

    func openChallenges() {
        selectedTab = Self.challengesTab
    }

    func openProfile() {
        selectedTab = Self.profileTab
    }
}
