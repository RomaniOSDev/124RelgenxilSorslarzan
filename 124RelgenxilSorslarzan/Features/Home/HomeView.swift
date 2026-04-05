import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var progress: ProgressRepository
    @EnvironmentObject private var tabRouter: MainTabRouter
    @State private var heroPulse = false

    private var maxStarsTotal: Int {
        ActivityKind.allCases.count * DifficultyTier.allCases.count * LevelsConfig.countPerTier * 3
    }

    private var totalStars: Int {
        progress.totalStarsAcrossAllActivities()
    }

    private var progressFraction: Double {
        guard maxStarsTotal > 0 else { return 0 }
        return min(1, Double(totalStars) / Double(maxStarsTotal))
    }

    private var levelsClearedCount: Int {
        var n = 0
        for activity in ActivityKind.allCases {
            for tier in DifficultyTier.allCases {
                for level in 1 ... LevelsConfig.countPerTier {
                    if progress.stars(activity: activity, tier: tier, level: level) > 0 {
                        n += 1
                    }
                }
            }
        }
        return n
    }

    private let totalLevelSlots = ActivityKind.allCases.count * DifficultyTier.allCases.count * LevelsConfig.countPerTier

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                heroSection
                masterySection
                quickActionsSection
                focusCard(title: nextFocusContent.title, detail: nextFocusContent.detail)
                activitiesSection
                achievementsSnapshot
                tipsCarousel
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .appScreenBackdrop()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(AppMotion.spring.repeatForever(autoreverses: true)) {
                heroPulse = true
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppChrome.surfaceCard)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppChrome.surfaceCardDepth)
                        .opacity(0.55)
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppChrome.cardSheen)
                    HomeHeroCanvas(pulse: heroPulse)
                        .frame(height: 132)
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppChrome.cardRim, lineWidth: 1)
                )
                .appCardShadowElevated()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Overview")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appAccent)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Text("Plan routes, read the map, move with purpose.")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appBackground.opacity(0.88), Color.appBackground.opacity(0.58)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.appAccent.opacity(0.22), lineWidth: 1)
                )
                .appCardShadowFloating()
                .padding(12)
            }

            HStack(spacing: 12) {
                heroStatPill(
                    icon: "star.fill",
                    value: "\(totalStars)",
                    label: "Stars",
                    sublabel: "of \(maxStarsTotal)"
                )
                heroStatPill(
                    icon: "checkmark.circle.fill",
                    value: "\(levelsClearedCount)",
                    label: "Stages",
                    sublabel: "of \(totalLevelSlots)"
                )
                heroStatPill(
                    icon: "clock.fill",
                    value: formattedShortTime(progress.totalPlaySeconds),
                    label: "Practice",
                    sublabel: "total"
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func heroStatPill(icon: String, value: String, label: String, sublabel: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appAccent)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(sublabel)
                .font(.caption2)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .appElevatedCard(cornerRadius: 14)
    }

    private var masterySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Overall mastery")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer(minLength: 8)
                Text("\(Int(progressFraction * 100))%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appAccent)
                    .appButtonLabel()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appBackground, Color.appBackground.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.appTextSecondary.opacity(0.14), lineWidth: 1)
                        )
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary.opacity(0.95), Color.appAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * progressFraction))
                        .shadow(color: Color.appPrimary.opacity(0.5), radius: 6, x: 0, y: 2)
                        .animation(AppMotion.ease, value: progressFraction)
                }
            }
            .frame(height: 12)
            Text("Earn stars across every tier to fill the bar.")
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .appElevatedCard(cornerRadius: 16)
    }

    private var quickChallengeButton: some View {
        Button {
            withAnimation(AppMotion.spring) {
                tabRouter.openChallenges()
            }
        } label: {
            Label("Challenges", systemImage: "map.fill")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .appButtonLabel()
        }
        .buttonStyle(AppPrimaryButtonStyle())
    }

    private var quickProfileButton: some View {
        Button {
            withAnimation(AppMotion.spring) {
                tabRouter.openProfile()
            }
        } label: {
            Label("Profile", systemImage: "person.crop.circle")
                .labelStyle(.titleAndIcon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .appButtonLabel()
        }
        .buttonStyle(AppSecondaryButtonStyle())
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .appTitleDepth()
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    quickChallengeButton
                    quickProfileButton
                }
                VStack(spacing: 12) {
                    quickChallengeButton
                    quickProfileButton
                }
            }
        }
    }

    private var nextFocusContent: (title: String, detail: String) {
        for activity in ActivityKind.allCases {
            for tier in DifficultyTier.allCases {
                for level in 1 ... LevelsConfig.countPerTier {
                    if progress.isLevelUnlocked(activity: activity, tier: tier, level: level),
                       progress.stars(activity: activity, tier: tier, level: level) < 3 {
                        return (
                            "Next focus: \(activity.displayTitle)",
                            "\(tier.displayTitle) · Stage \(level) — room to earn more stars."
                        )
                    }
                }
            }
        }
        if progress.totalActivitiesCompleted == 0 {
            return (
                "Start your first run",
                "Open Challenges, pick any activity, and clear Easy stage 1."
            )
        }
        return (
            "Strong progress",
            "Replay any stage to tighten times or chase three stars on every tier."
        )
    }

    private func focusCard(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                tabRouter.openChallenges()
            } label: {
                Text("Go to Challenges")
                    .appButtonLabel()
            }
            .buttonStyle(AppPrimaryButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppChrome.surfaceCard)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.14), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.appPrimary.opacity(0.45), Color.appAccent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .appCardShadowElevated()
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activities")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Button {
                    tabRouter.openChallenges()
                } label: {
                    Text("See all")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                        .appButtonLabel()
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
            VStack(spacing: 10) {
                ForEach(ActivityKind.allCases, id: \.self) { activity in
                    activityRow(activity)
                }
            }
        }
    }

    private func activityRow(_ activity: ActivityKind) -> some View {
        let stars = progress.totalStars(for: activity)
        return Button {
            tabRouter.openChallenges()
        } label: {
            HStack(spacing: 14) {
                ActivityGlyphView(activity: activity)
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    StarRowView(
                        value: min(12, stars),
                        maxValue: 12,
                        starDimension: 12,
                        starSpacing: 3
                    )
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 20)
            }
            .padding(14)
            .appElevatedCard(cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }

    private var achievementsSnapshot: some View {
        let unlocked = progress.unlockedAchievements().count
        let total = progress.achievementDefinitions.count
        return VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.appTextSecondary.opacity(0.22), Color.appBackground.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 6
                        )
                    Circle()
                        .trim(from: 0, to: total > 0 ? CGFloat(unlocked) / CGFloat(total) : 0)
                        .stroke(
                            AngularGradient(
                                colors: [Color.appAccent, Color.appPrimary, Color.appAccent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Color.appPrimary.opacity(0.35), radius: 6, x: 0, y: 2)
                    Text("\(unlocked)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                }
                .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(unlocked) of \(total) unlocked")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Finish runs and collect stars to reveal more badges.")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        tabRouter.openProfile()
                    } label: {
                        Text("View in Profile")
                            .font(.subheadline.weight(.semibold))
                            .appButtonLabel()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.appAccent)
                    .frame(minHeight: 44, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .appElevatedCard(cornerRadius: 16)
        }
    }

    private var tipsCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Field notes")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    tipChip(
                        icon: "point.topleft.down.curvedto.point.bottomright.up",
                        title: "Pin control",
                        text: "Small drags on the map move coordinates a lot—adjust with patience."
                    )
                    tipChip(
                        icon: "scope",
                        title: "Landmarks",
                        text: "Cross-check clues with shoreline bends and major avenues."
                    )
                    tipChip(
                        icon: "location.north.line.fill",
                        title: "Compass runs",
                        text: "Let cues stack up before spamming steps on harder tiers."
                    )
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func tipChip(icon: String, title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
            Text(text)
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(width: 240, alignment: .leading)
        .appElevatedCard(cornerRadius: 14)
    }

    private func formattedShortTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        if m > 0 {
            return "\(m)m"
        }
        return "\(total)s"
    }
}

private struct HomeHeroCanvas: View {
    let pulse: Bool

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var grid = Path()
            let step: CGFloat = 22
            var gx: CGFloat = 16
            while gx < w - 8 {
                grid.move(to: CGPoint(x: gx, y: 12))
                grid.addLine(to: CGPoint(x: gx, y: h - 12))
                gx += step
            }
            var gy: CGFloat = 12
            while gy < h - 8 {
                grid.move(to: CGPoint(x: 16, y: gy))
                grid.addLine(to: CGPoint(x: w - 16, y: gy))
                gy += step
            }
            context.stroke(grid, with: .color(Color.appTextSecondary.opacity(0.12)), lineWidth: 1)

            var route = Path()
            route.move(to: CGPoint(x: 24, y: h * 0.72))
            route.addQuadCurve(
                to: CGPoint(x: w - 28, y: h * 0.28),
                control: CGPoint(x: w * 0.48, y: h * 0.42 + (pulse ? 6 : 0))
            )
            context.stroke(
                route,
                with: .color(Color.appAccent.opacity(0.85)),
                style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 7])
            )

            let pinY = h * 0.62 + (pulse ? 3 : 0)
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.42 - 6, y: pinY - 28, width: 12, height: 12)),
                with: .color(Color.appPrimary)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.42 - 10, y: pinY - 12, width: 20, height: 20)),
                with: .color(Color.appAccent.opacity(0.75))
            )
        }
        .allowsHitTesting(false)
    }
}
