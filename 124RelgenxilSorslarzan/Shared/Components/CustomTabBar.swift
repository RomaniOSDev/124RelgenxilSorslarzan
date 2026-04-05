import SwiftUI

struct CustomTabBar: View {
    @Binding var selection: Int

    private let items: [(title: String, systemImage: String)] = [
        ("Home", "house.fill"),
        ("Challenges", "map.fill"),
        ("Profile", "person.crop.circle")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    withAnimation(AppMotion.spring) {
                        selection = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 20, weight: .semibold))
                            .shadow(color: selection == index ? Color.appPrimary.opacity(0.45) : .clear, radius: 6, y: 2)
                        Text(item.title)
                            .font(.caption.weight(.semibold))
                            .appButtonLabel()
                    }
                    .foregroundStyle(selection == index ? Color.appPrimary : Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background {
            ZStack(alignment: .top) {
                AppChrome.tabBarFill
                LinearGradient(
                    colors: [Color.appAccent.opacity(0.4), Color.appAccent.opacity(0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 5)
                .allowsHitTesting(false)
            }
        }
        .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: -8)
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 28, x: 0, y: -4)
    }
}
