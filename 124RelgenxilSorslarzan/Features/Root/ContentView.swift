import SwiftUI

struct ContentView: View {
    @StateObject private var progress = ProgressRepository()

    var body: some View {
        Group {
            if progress.hasSeenOnboarding {
                MainTabShellView()
            } else {
                OnboardingFlowView()
            }
        }
        .environmentObject(progress)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
