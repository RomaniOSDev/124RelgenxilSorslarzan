import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollScreen(title: "Settings") {
            VStack(alignment: .leading, spacing: 14) {
                settingsButton(
                    title: "Rate us",
                    systemImage: "star.fill",
                    action: rateApp
                )
                settingsButton(
                    title: "Privacy Policy",
                    systemImage: "hand.raised.fill",
                    action: { openPolicy(.privacyPolicy) }
                )
                settingsButton(
                    title: "Terms of Use",
                    systemImage: "doc.text.fill",
                    action: { openPolicy(.termsOfUse) }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(Color.appAccent)
            }
        }
    }

    private func openPolicy(_ link: AppExternalLink) {
        if let url = URL(string: link.rawValue) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 28, alignment: .center)
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(16)
            .appInsetPlate(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
