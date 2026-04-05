import SwiftUI

struct MainTabShellView: View {
    @StateObject private var tabRouter = MainTabRouter()

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tabRouter.selectedTab {
                case MainTabRouter.homeTab:
                    NavigationStack {
                        HomeView()
                    }
                case MainTabRouter.challengesTab:
                    NavigationStack {
                        ChallengeHubView()
                    }
                case MainTabRouter.profileTab:
                    NavigationStack {
                        ProfileDashboardView()
                    }
                default:
                    NavigationStack {
                        HomeView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            CustomTabBar(
                selection: Binding(
                    get: { tabRouter.selectedTab },
                    set: { tabRouter.selectedTab = $0 }
                )
            )
        }
        .environmentObject(tabRouter)
        .appScreenBackdrop(deep: true)
    }
}
