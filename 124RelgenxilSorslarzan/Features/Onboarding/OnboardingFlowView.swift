import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var progress: ProgressRepository
    @State private var page = 0
    @State private var pulse = false

    private let titles = [
        "Navigate with clarity",
        "Train on real scenarios",
        "Collect stars for mastery"
    ]

    private let subtitles = [
        "Explore interactive maps, plot paths, and read terrain with confidence.",
        "Detours, obstacles, and directional puzzles adapt to your skill level.",
        "Aim for accuracy, speed, and clean finishes to earn up to three stars per challenge."
    ]

    var body: some View {
        GeometryReader { geo in
            let illustrationHeight = min(max(geo.size.height * 0.34, 220), 300)
            let bottomInset = max(geo.safeAreaInsets.bottom, 20)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                TabView(selection: $page) {
                    ForEach(0 ..< 3, id: \.self) { index in
                        OnboardingPageIllustration(index: index, pulse: pulse)
                            .padding(.horizontal, 10)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: illustrationHeight)

                OnboardingPageIndicator(selection: $page, count: 3)
                    .padding(.top, 18)
                    .padding(.bottom, 10)

                Spacer(minLength: 0)

                VStack(alignment: .center, spacing: 14) {
                    Text(titles[page])
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.center)
                        .appTitleDepth()
                        .animation(AppMotion.ease, value: page)

                    Text(subtitles[page])
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(8)
                        .minimumScaleFactor(0.88)
                        .animation(AppMotion.ease, value: page)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                .appInsetPlate(cornerRadius: 22)
                .padding(.horizontal, 18)

                Spacer(minLength: 0)

                Group {
                    if page < 2 {
                        Button {
                            withAnimation(AppMotion.spring) {
                                page += 1
                            }
                        } label: {
                            Text("Continue")
                                .appButtonLabel()
                        }
                        .buttonStyle(AppPrimaryButtonStyle())
                    } else {
                        Button {
                            progress.completeOnboarding()
                        } label: {
                            Text("Get Started")
                                .appButtonLabel()
                        }
                        .buttonStyle(AppPrimaryButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, geo.safeAreaInsets.top + 12)
            .padding(.bottom, bottomInset + 8)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .appScreenBackdrop(deep: true)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            withAnimation(AppMotion.spring.repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct OnboardingPageIndicator: View {
    @Binding var selection: Int
    let count: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0 ..< count, id: \.self) { index in
                Button {
                    withAnimation(AppMotion.spring) {
                        selection = index
                    }
                } label: {
                    ZStack {
                        if index == selection {
                            Capsule()
                                .fill(AppChrome.primaryButtonFill)
                                .overlay(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.appTextPrimary.opacity(0.22), Color.clear],
                                                startPoint: .top,
                                                endPoint: .center
                                            )
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.appTextPrimary.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color.appPrimary.opacity(0.5), radius: 8, x: 0, y: 4)
                                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                        } else {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appSurface.opacity(0.55),
                                            Color.appBackground.opacity(0.72)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Capsule()
                                        .fill(AppChrome.cardSheen.opacity(0.5))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.appAccent.opacity(0.22), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.22), radius: 3, x: 0, y: 2)
                        }
                    }
                    .frame(width: index == selection ? 26 : 9, height: 9)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Page \(index + 1) of \(count)")
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 20)
    }
}

private struct OnboardingPageIllustration: View {
    let index: Int
    let pulse: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            switch index {
            case 0:
                drawMapGrid(in: context, size: size, center: center, pulse: pulse)
            case 1:
                drawDetour(in: context, size: size, center: center, pulse: pulse)
            default:
                drawStars(in: context, size: size, center: center, pulse: pulse)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appElevatedCard(cornerRadius: 26)
    }

    private func drawMapGrid(in context: GraphicsContext, size: CGSize, center: CGPoint, pulse: Bool) {
        let gridColor = Color.appAccent.opacity(0.45)
        let line = Color.appTextSecondary.opacity(0.35)
        let step: CGFloat = 26
        var x: CGFloat = 20
        while x < size.width - 20 {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 20))
            path.addLine(to: CGPoint(x: x, y: size.height - 20))
            context.stroke(path, with: .color(line), lineWidth: 1)
            x += step
        }
        var y: CGFloat = 20
        while y < size.height - 20 {
            var path = Path()
            path.move(to: CGPoint(x: 20, y: y))
            path.addLine(to: CGPoint(x: size.width - 20, y: y))
            context.stroke(path, with: .color(line), lineWidth: 1)
            y += step
        }
        let pinR: CGFloat = pulse ? 16 : 12
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - 10, y: center.y - 30, width: 20, height: 20)),
            with: .color(Color.appPrimary)
        )
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - pinR, y: center.y - 6, width: pinR * 2, height: pinR * 2)),
            with: .color(Color.appAccent.opacity(0.85))
        )
        context.stroke(
            Path(ellipseIn: CGRect(x: center.x - pinR, y: center.y - 6, width: pinR * 2, height: pinR * 2)),
            with: .color(gridColor),
            lineWidth: 2
        )
    }

    private func drawDetour(in context: GraphicsContext, size: CGSize, center: CGPoint, pulse: Bool) {
        let obstacle = CGRect(x: center.x - 40, y: center.y - 20, width: 80, height: 60)
        context.fill(Path(roundedRect: obstacle, cornerRadius: 10), with: .color(Color.appSurface.opacity(0.9)))
        context.stroke(Path(roundedRect: obstacle, cornerRadius: 10), with: .color(Color.appPrimary.opacity(0.65)), lineWidth: 2)

        var route = Path()
        route.move(to: CGPoint(x: 30, y: size.height - 40))
        route.addQuadCurve(to: CGPoint(x: size.width - 30, y: 40), control: CGPoint(x: center.x + (pulse ? 30 : 10), y: center.y - 50))
        context.stroke(route, with: .color(Color.appAccent), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [10, 8]))

        context.fill(Path(ellipseIn: CGRect(x: 22, y: size.height - 48, width: 16, height: 16)), with: .color(Color.appPrimary))
        context.fill(Path(ellipseIn: CGRect(x: size.width - 38, y: 32, width: 16, height: 16)), with: .color(Color.appPrimary))
    }

    private func drawStars(in context: GraphicsContext, size: CGSize, center: CGPoint, pulse: Bool) {
        let offsets: [CGFloat] = [-48, 0, 48]
        for (i, dx) in offsets.enumerated() {
            let scale = pulse ? (i == 1 ? 1.15 : 1.05) : 1
            let rect = CGRect(x: center.x + dx - 18 * scale, y: center.y - 18 * scale, width: 36 * scale, height: 36 * scale)
            var path = Path()
            let c = CGPoint(x: rect.midX, y: rect.midY)
            let r = min(rect.width, rect.height) / 2 * 0.9
            let points = 5
            for p in 0 ..< (points * 2) {
                let angle = CGFloat(p) * .pi / CGFloat(points) - .pi / 2
                let radius = p.isMultiple(of: 2) ? r : r * 0.45
                let pt = CGPoint(x: c.x + cos(angle) * radius, y: c.y + sin(angle) * radius)
                if p == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            context.fill(path, with: .color(Color.appPrimary.opacity(0.85)))
            context.stroke(path, with: .color(Color.appAccent.opacity(0.9)), lineWidth: 1.5)
        }
    }
}
