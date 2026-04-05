import Combine
import Foundation

@MainActor
final class CompassChallengeViewModel: ObservableObject {
    struct GridSize {
        let columns: Int
        let rows: Int
    }

    let tier: DifficultyTier
    let level: Int

    @Published private(set) var grid: GridSize
    @Published private(set) var player: CGPoint
    @Published private(set) var target: CGPoint
    private let startPosition: CGPoint
    @Published private(set) var movesUsed: Int = 0
    @Published private(set) var cue: String = "Take your first step."
    @Published private(set) var phase: Phase = .playing
    @Published var elapsed: TimeInterval = 0

    private var timerCancellable: AnyCancellable?
    private var startedAt: Date?
    let maxSteps: Int
    private let cueStride: Int
    private var movesSinceCue = 0

    enum Phase: Equatable {
        case playing
        case success
        case overLimit
    }

    init(tier: DifficultyTier, level: Int) {
        self.tier = tier
        self.level = level
        let columns = switch tier {
        case .easy: 7 + level / 2
        case .normal: 9 + level / 2
        case .hard: 11 + level / 2
        }
        let rows = columns
        self.grid = GridSize(columns: columns, rows: rows)
        self.maxSteps = switch tier {
        case .easy: 70 - level * 3
        case .normal: 58 - level * 3
        case .hard: 46 - level * 3
        }
        self.cueStride = switch tier {
        case .easy: 2
        case .normal: 4
        case .hard: 7
        }
        var generator = CompassGenerator(seed: CompassChallengeViewModel.seed(tier: tier, level: level))
        let px = CGFloat(generator.nextInt(in: 1 ..< columns - 1))
        let py = CGFloat(generator.nextInt(in: 1 ..< rows - 1))
        var tx = CGFloat(generator.nextInt(in: 1 ..< columns - 1))
        var ty = CGFloat(generator.nextInt(in: 1 ..< rows - 1))
        while abs(tx - px) + abs(ty - py) < CGFloat(3 + level / 2) {
            tx = CGFloat(generator.nextInt(in: 1 ..< columns - 1))
            ty = CGFloat(generator.nextInt(in: 1 ..< rows - 1))
        }
        let origin = CGPoint(x: px, y: py)
        self.startPosition = origin
        self.player = origin
        self.target = CGPoint(x: tx, y: ty)
        refreshCue(force: true)
    }

    func startClock() {
        guard startedAt == nil else { return }
        startedAt = Date()
        timerCancellable = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let startedAt = self.startedAt else { return }
                self.elapsed = Date().timeIntervalSince(startedAt)
            }
    }

    func stopClock() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func move(dx: Int, dy: Int) {
        guard phase == .playing else { return }
        var next = player
        next.x += CGFloat(dx)
        next.y += CGFloat(dy)
        next.x = min(CGFloat(grid.columns - 1), max(0, next.x))
        next.y = min(CGFloat(grid.rows - 1), max(0, next.y))
        player = next
        movesUsed += 1
        movesSinceCue += 1
        if player == target {
            phase = .success
            cue = "Target reached."
            stopClock()
            return
        }
        if movesUsed >= maxSteps {
            phase = .overLimit
            cue = "Step budget exhausted."
            stopClock()
            return
        }
        if movesSinceCue >= cueStride {
            refreshCue(force: false)
            movesSinceCue = 0
        }
    }

    func evaluateOutcome() -> (stars: Int, accuracy: Int) {
        switch phase {
        case .success:
            let optimalSteps = Int(abs(target.x - startPosition.x) + abs(target.y - startPosition.y))
            let timeLimit: TimeInterval = switch tier {
            case .easy: 90
            case .normal: 75
            case .hard: 60
            }
            let headroom = max(0, optimalSteps + 6 + level - movesUsed)
            let baseAccuracy = min(100, 86 + headroom * 2)
            if movesUsed <= optimalSteps + 4 + level, elapsed <= timeLimit {
                return (3, baseAccuracy)
            }
            if movesUsed <= optimalSteps + 10 + level {
                return (2, min(100, baseAccuracy - 8))
            }
            return (1, 62)
        case .overLimit, .playing:
            return (0, 25)
        }
    }

    private func refreshCue(force: Bool) {
        let dx = Int(target.x - player.x)
        let dy = Int(target.y - player.y)
        if dx == 0 && dy == 0 {
            cue = "You are aligned."
            return
        }
        var parts: [String] = []
        if dy < 0 {
            parts.append("Head north")
        } else if dy > 0 {
            parts.append("Head south")
        }
        if dx > 0 {
            parts.append("shift east")
        } else if dx < 0 {
            parts.append("shift west")
        }
        cue = parts.joined(separator: ", ") + "."
        if force {
            movesSinceCue = 0
        }
    }

    private static func seed(tier: DifficultyTier, level: Int) -> UInt64 {
        var hasher = Hasher()
        hasher.combine("compass")
        hasher.combine(tier.rawValue)
        hasher.combine(level)
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }
}

private struct CompassGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xC0DE_F00D : seed
    }

    mutating func next() -> UInt64 {
        state &*= 6364136223846793005
        state &+= 1442695040888963407
        return state
    }

    mutating func nextInt(in range: Range<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound)
        let value = next() % max(span, 1)
        return range.lowerBound + Int(value)
    }
}
