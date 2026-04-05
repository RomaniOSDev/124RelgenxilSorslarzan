import SwiftUI

struct ProfileDashboardView: View {
    @EnvironmentObject private var progress: ProgressRepository
    @State private var showResetConfirm = false
    @State private var showSettings = false

    var body: some View {
        ScrollScreen(title: "Profile") {
            VStack(alignment: .leading, spacing: 18) {
                settingsEntry
                statsCard
                achievementsSection
                resetSection
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Reset all progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                progress.resetAllProgress()
            }
        } message: {
            Text("This clears stars, unlocks, totals, achievements visibility, and shows onboarding again.")
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }

    private var settingsEntry: some View {
        Button {
            showSettings = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "gearshape.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 36, alignment: .center)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Rate us, privacy, and terms")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appElevatedCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            statRow(label: "Challenges completed", value: "\(progress.totalActivitiesCompleted)")
            statRow(label: "Total practice time", value: formattedTime(progress.totalPlaySeconds))
            statRow(label: "Stars collected", value: "\(progress.totalStarsAcrossAllActivities())")
            if progress.totalActivitiesCompleted == 0 {
                Text("Complete a challenge to start filling these numbers.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 16)
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .appButtonLabel()
        }
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            let items = progress.achievementDefinitions
            if items.allSatisfy({ !$0.isUnlocked(progress) }) {
                Text("Finish challenges to unlock achievements. They update automatically from your saved progress.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(items) { item in
                let unlocked = item.isUnlocked(progress)
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(unlocked ? Color.appPrimary : Color.appSurface)
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(unlocked ? Color.appTextPrimary : Color.appTextSecondary)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Text(unlocked ? "Unlocked" : "Locked")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(unlocked ? Color.appAccent : Color.appTextSecondary)
                        .appButtonLabel()
                }
                .padding(12)
                .appInsetPlate(cornerRadius: 12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 16)
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Danger zone")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            Text("Reset clears saved progress on this device and returns the first-launch tour.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showResetConfirm = true
            } label: {
                Text("Reset All Progress")
                    .appButtonLabel()
            }
            .buttonStyle(AppSecondaryButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard(cornerRadius: 16)
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%dh %02dm", h, m)
        }
        return String(format: "%dm %02ds", m, s)
    }
}
