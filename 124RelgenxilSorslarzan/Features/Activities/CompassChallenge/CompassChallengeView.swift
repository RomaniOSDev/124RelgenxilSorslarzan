import SwiftUI

struct CompassChallengeView: View {
    @EnvironmentObject private var progress: ProgressRepository
    @StateObject private var viewModel: CompassChallengeViewModel
    @Binding var path: [ChallengeNavDestination]

    private let activity: ActivityKind = .compassChallenge

    init(tier: DifficultyTier, level: Int, path: Binding<[ChallengeNavDestination]>) {
        _viewModel = StateObject(wrappedValue: CompassChallengeViewModel(tier: tier, level: level))
        _path = path
    }

    private var tier: DifficultyTier { viewModel.tier }
    private var level: Int { viewModel.level }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Compass Challenge")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .appTitleDepth()
                Text("Follow the cues. Each tap moves one grid step toward the heading you choose.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text("Moves")
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                    Text("\(viewModel.movesUsed) / \(viewModel.maxSteps)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Color.appPrimary)
                        .appButtonLabel()
                }
                .padding(12)
                .appElevatedCard(cornerRadius: 12)

                HStack {
                    Text("Elapsed")
                        .foregroundStyle(Color.appTextSecondary)
                    Spacer()
                    Text(formattedTime(viewModel.elapsed))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Color.appPrimary)
                        .appButtonLabel()
                }
                .padding(12)
                .appElevatedCard(cornerRadius: 12)

                CompassGridCanvas(
                    columns: viewModel.grid.columns,
                    rows: viewModel.grid.rows,
                    player: viewModel.player,
                    target: viewModel.target
                )
                .frame(height: 320)
                .background(
                    LinearGradient(
                        colors: [Color.appBackground, Color.appSurface.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppChrome.cardRim, lineWidth: 1)
                )
                .appCardShadowElevated()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Active cue")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text(viewModel.cue)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appElevatedCard(cornerRadius: 14)

                directionPad

                if viewModel.phase != .playing {
                    Button {
                        finalize()
                    } label: {
                        Text("Continue to results")
                            .appButtonLabel()
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.hidden)
        .appScreenBackdrop()
        .onAppear { viewModel.startClock() }
        .onDisappear { viewModel.stopClock() }
    }

    private var directionPad: some View {
        VStack(spacing: 10) {
            directionButton(title: "North", systemImage: "arrow.up") {
                viewModel.move(dx: 0, dy: -1)
            }
            HStack(spacing: 10) {
                directionButton(title: "West", systemImage: "arrow.left") {
                    viewModel.move(dx: -1, dy: 0)
                }
                directionButton(title: "East", systemImage: "arrow.right") {
                    viewModel.move(dx: 1, dy: 0)
                }
            }
            directionButton(title: "South", systemImage: "arrow.down") {
                viewModel.move(dx: 0, dy: 1)
            }
        }
    }

    private func directionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .appButtonLabel()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 16)
        }
        .buttonStyle(AppSecondaryButtonStyle())
        .disabled(viewModel.phase != .playing)
    }

    private func finalize() {
        let result = viewModel.evaluateOutcome()
        viewModel.stopClock()
        ChallengeCompletion.finish(
            progress: progress,
            path: $path,
            activity: activity,
            tier: tier,
            level: level,
            stars: result.stars,
            duration: viewModel.elapsed,
            accuracyPercent: result.accuracy
        )
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct CompassGridCanvas: View {
    let columns: Int
    let rows: Int
    let player: CGPoint
    let target: CGPoint

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(max(columns, 1))
            let cellH = geo.size.height / CGFloat(max(rows, 1))
            Canvas { context, size in
                for x in 0 ..< columns {
                    for y in 0 ..< rows {
                        let rect = CGRect(
                            x: CGFloat(x) * cellW + 1,
                            y: CGFloat(y) * cellH + 1,
                            width: cellW - 2,
                            height: cellH - 2
                        )
                        let path = Path(roundedRect: rect, cornerRadius: 4)
                        context.fill(path, with: .color(Color.appSurface.opacity(0.55)))
                        context.stroke(path, with: .color(Color.appAccent.opacity(0.25)), lineWidth: 1)
                    }
                }

                let targetRect = CGRect(
                    x: CGFloat(target.x) * cellW + cellW * 0.2,
                    y: CGFloat(target.y) * cellH + cellH * 0.2,
                    width: cellW * 0.6,
                    height: cellH * 0.6
                )
                context.stroke(
                    Path(ellipseIn: targetRect),
                    with: .color(Color.appAccent),
                    style: StrokeStyle(lineWidth: 3, dash: [6, 4])
                )

                let playerCenter = CGPoint(
                    x: CGFloat(player.x) * cellW + cellW / 2,
                    y: CGFloat(player.y) * cellH + cellH / 2
                )
                let playerPath = Path(ellipseIn: CGRect(x: playerCenter.x - 9, y: playerCenter.y - 9, width: 18, height: 18))
                context.fill(playerPath, with: .color(Color.appPrimary))
                context.stroke(playerPath, with: .color(Color.appBackground), lineWidth: 2)
            }
        }
    }
}
