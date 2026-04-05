import SwiftUI

struct ActivityGlyphView: View {
    let activity: ActivityKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.9), Color.appBackground.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppChrome.cardSheen.opacity(0.85))
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppChrome.cardRim.opacity(0.75), lineWidth: 1)
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                switch activity {
                case .routeNavigator:
                    var path = Path()
                    path.move(to: CGPoint(x: 12, y: size.height - 12))
                    path.addQuadCurve(to: CGPoint(x: size.width - 12, y: 12), control: CGPoint(x: size.width * 0.45, y: size.height * 0.55))
                    context.stroke(path, with: .color(Color.appAccent), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    context.fill(Path(ellipseIn: CGRect(x: 8, y: size.height - 20, width: 10, height: 10)), with: .color(Color.appPrimary))
                case .landmarkLocator:
                    let rect = CGRect(x: center.x - 22, y: center.y - 18, width: 44, height: 36)
                    context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(Color.appAccent), lineWidth: 2)
                    context.fill(Path(ellipseIn: CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)), with: .color(Color.appPrimary))
                case .compassChallenge:
                    let ring = Path(ellipseIn: CGRect(x: center.x - 20, y: center.y - 20, width: 40, height: 40))
                    context.stroke(ring, with: .color(Color.appAccent), lineWidth: 2)
                    var needle = Path()
                    needle.move(to: center)
                    needle.addLine(to: CGPoint(x: center.x, y: center.y - 18))
                    context.stroke(needle, with: .color(Color.appPrimary), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .appCardShadowSoft()
    }
}
