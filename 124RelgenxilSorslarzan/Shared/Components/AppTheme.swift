import SwiftUI

enum AppMotion {
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let ease = Animation.easeInOut(duration: 0.35)
}

// MARK: - Gradients & depth (asset colors only)

enum AppChrome {
    static let screenBackdrop = LinearGradient(
        colors: [
            Color.appBackground,
            Color.appSurface.opacity(0.42),
            Color.appBackground
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let screenBackdropDeep = LinearGradient(
        colors: [
            Color.appBackground,
            Color.appSurface.opacity(0.28),
            Color.appSurface.opacity(0.5),
            Color.appBackground
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let surfaceCard = LinearGradient(
        colors: [
            Color.appSurface.opacity(0.98),
            Color.appSurface.opacity(0.72)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surfaceCardDepth = LinearGradient(
        colors: [
            Color.appSurface.opacity(0.55),
            Color.appBackground.opacity(0.88)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardRim = LinearGradient(
        colors: [Color.appAccent.opacity(0.42), Color.appAccent.opacity(0.06)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardSheen = LinearGradient(
        colors: [Color.appTextPrimary.opacity(0.11), Color.clear],
        startPoint: .top,
        endPoint: UnitPoint(x: 0.5, y: 0.5)
    )

    static let primaryButtonFill = LinearGradient(
        colors: [Color.appPrimary, Color.appAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tabBarFill = LinearGradient(
        colors: [
            Color.appSurface.opacity(0.98),
            Color.appSurface.opacity(0.88),
            Color.appBackground.opacity(0.92)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let tabBarTopGlow = LinearGradient(
        colors: [Color.appAccent.opacity(0.35), Color.clear],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - View extensions

extension View {
    func appButtonLabel() -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
    }

    func appScreenBackdrop(deep: Bool = false) -> some View {
        background(
            Group {
                if deep {
                    AppChrome.screenBackdropDeep
                } else {
                    AppChrome.screenBackdrop
                }
            }
            .ignoresSafeArea()
        )
    }

    func appCardShadowElevated() -> some View {
        shadow(color: Color.black.opacity(0.48), radius: 16, x: 0, y: 10)
            .shadow(color: Color.appPrimary.opacity(0.12), radius: 22, x: 0, y: 4)
    }

    func appCardShadowSoft() -> some View {
        shadow(color: Color.black.opacity(0.38), radius: 12, x: 0, y: 7)
            .shadow(color: Color.appAccent.opacity(0.08), radius: 18, x: 0, y: 3)
    }

    func appCardShadowFloating() -> some View {
        shadow(color: Color.black.opacity(0.32), radius: 10, x: 0, y: 6)
            .shadow(color: Color.appPrimary.opacity(0.08), radius: 16, x: 0, y: 2)
    }

    /// Use after `.padding(...)` on card content.
    func appElevatedCard(cornerRadius: CGFloat = 16) -> some View {
        background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppChrome.surfaceCard)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppChrome.surfaceCardDepth)
                    .opacity(0.65)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppChrome.cardSheen)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppChrome.cardRim, lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .appCardShadowElevated()
    }

    func appInsetPlate(cornerRadius: CGFloat = 12) -> some View {
        background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appBackground.opacity(0.94),
                                Color.appSurface.opacity(0.38)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.appAccent.opacity(0.14), lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .appCardShadowSoft()
    }

    func appTitleDepth() -> some View {
        shadow(color: Color.black.opacity(0.35), radius: 1, x: 0, y: 1)
            .shadow(color: Color.appPrimary.opacity(0.12), radius: 8, x: 0, y: 2)
    }

    func appLevelCellChrome(unlocked: Bool, cornerRadius: CGFloat = 12) -> some View {
        background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: unlocked
                                ? [Color.appBackground.opacity(0.96), Color.appSurface.opacity(0.5)]
                                : [Color.appBackground.opacity(0.5), Color.appBackground.opacity(0.32)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appTextPrimary.opacity(unlocked ? 0.06 : 0.03), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.appAccent.opacity(unlocked ? 0.4 : 0.14),
                        lineWidth: 1
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(unlocked ? 0.32 : 0.18), radius: unlocked ? 8 : 4, x: 0, y: unlocked ? 5 : 2)
    }
}

// MARK: - Buttons

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.appBackground)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppChrome.primaryButtonFill)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appTextPrimary.opacity(0.18), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.appTextPrimary.opacity(0.2), lineWidth: 1)
                }
                .opacity(configuration.isPressed ? 0.88 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.appPrimary.opacity(configuration.isPressed ? 0.2 : 0.45), radius: 10, x: 0, y: 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AppMotion.ease, value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.appTextPrimary)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppChrome.surfaceCard)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppChrome.cardSheen.opacity(0.9))
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppChrome.cardRim, lineWidth: 1)
                }
                .opacity(configuration.isPressed ? 0.9 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .appCardShadowSoft()
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AppMotion.ease, value: configuration.isPressed)
    }
}

// MARK: - Stars

struct StarGlyphView: View {
    let filled: Bool
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 * 0.92
            var path = Path()
            let points = 5
            for i in 0 ..< (points * 2) {
                let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
                let r = i.isMultiple(of: 2) ? radius : radius * 0.45
                let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            context.fill(path, with: .color(filled ? Color.appPrimary : Color.appSurface))
            context.stroke(path, with: .color(Color.appAccent.opacity(filled ? 0.9 : 0.4)), lineWidth: 1)
        }
        .shadow(color: Color.appPrimary.opacity(filled ? 0.4 : 0), radius: filled ? 5 : 0, x: 0, y: filled ? 2 : 0)
        .accessibilityLabel(filled ? "Star earned" : "Star locked")
    }
}

struct StarRowView: View {
    let value: Int
    let maxValue: Int
    var starDimension: CGFloat = 22
    var starSpacing: CGFloat = 6

    var body: some View {
        HStack(spacing: starSpacing) {
            ForEach(0 ..< maxValue, id: \.self) { index in
                StarGlyphView(filled: index < value)
                    .frame(width: starDimension, height: starDimension)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) of \(maxValue) stars")
    }
}
