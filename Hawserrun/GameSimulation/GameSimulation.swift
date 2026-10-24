import CoreGraphics
import Foundation

/// Published runner numbers. Contract units stay px/s and px/s^2 inside this type.
enum Physics {
    static let gravity: CGFloat = 2200
    static let runSpeed: CGFloat = 280
    static let jumpVelocity: CGFloat = 900
    static let minGap: CGFloat = 70
    static let maxGap: CGFloat = 160
    static let tradeoffDelta: CGFloat = 0.22
    /// Each cargo crate scales jump velocity by `1 - tradeoffDelta` (0.78).
    static var velocityScale: CGFloat { 1 - tradeoffDelta }
    static let reachFactor: CGFloat = 0.85
    static let chapters = 4
    static let nodeBudgetCap = 400
    static let poolCount = 6
    static let deckWidth: CGFloat = 240
    static let heelAmplitude: CGFloat = 18
    static let driftAmp: CGFloat = 8
    static let ledgeTravel: CGFloat = 12
    static let takeoffLead: CGFloat = 18
    static let hopPower: CGFloat = 0.62
    static let maxBurden = 3
    static let inputBuffer: CGFloat = 0.10
    static let hitStop: CGFloat = 0.05
    static let fixedStep: CGFloat = 1.0 / 120.0
    static let fixedSeed: UInt64 = 0x4853_5255_4E5A_2401
    /// Timing window published for the shared envelope helpers.
    static let window: CGFloat = 180
    static let minWindow: CGFloat = 90
    /// Loaded lift must still clear gravity after the tradeoff.
    static let lift: CGFloat = 3100
    static let restitution: CGFloat = 0.72

    static func scaledVelocity(burden: Int) -> CGFloat {
        var velocity = jumpVelocity
        for _ in 0..<max(0, burden) {
            velocity *= velocityScale
        }
        return velocity
    }

    static func placementExtra(kind: ObstacleKind) -> CGFloat {
        switch kind {
        case .gap:
            return 0
        case .drift:
            return driftAmp
        case .movingLedge:
            return ledgeTravel * 0.5
        }
    }

    /// Timing's next window is `max(minWindow, window * (1 - tradeoffDelta))`.
    static func nextWindow(window: CGFloat, minWindow: CGFloat, delta: CGFloat) -> CGFloat {
        max(minWindow, window * (1 - delta))
    }

    static func refusesWindow(_ window: CGFloat, minWindow: CGFloat = Physics.minWindow) -> Bool {
        window + 0.001 < minWindow
    }

    /// Flight's loaded lift is `lift * (1 - tradeoffDelta)`.
    static func loadedLift(lift: CGFloat, delta: CGFloat) -> CGFloat {
        lift * (1 - delta)
    }

    static func liftClearsGravity(lift: CGFloat, gravity: CGFloat, delta: CGFloat) -> Bool {
        loadedLift(lift: lift, delta: delta) > gravity
    }

    /// A drop's tilted restitution is `restitution * (1 - tradeoffDelta)`.
    static func tiltedRestitution(restitution: CGFloat, delta: CGFloat) -> CGFloat {
        restitution * (1 - delta)
    }

    static func apex(burden: Int) -> CGFloat {
        let velocity = scaledVelocity(burden: burden)
        return (velocity * velocity) / (2 * gravity)
    }

    static func refusesPocket(height: CGFloat, burden: Int) -> Bool {
        height > apex(burden: burden) + 0.001
    }
}

enum ObstacleKind: String, Sendable {
    case gap
    case drift
    case movingLedge
}

enum ReviewPose: String, CaseIterable, Sendable {
    case play
    case air
    case land
    case collect
    case hazard
    case fail
    case pause
    case chapter
}

enum NodeBudget {
    static func live(chunkCount: Int) -> Int {
        64 + chunkCount * 10
    }
}

struct BodyState: Sendable {
    var x: CGFloat = 48
    var y: CGFloat = 0
    var vy: CGFloat = 0
    var grounded = true
}

struct MooringBeat: Sendable {
    var index: Int
    var originX: CGFloat
    var deckWidth: CGFloat
    var gap: CGFloat
    var kind: ObstacleKind
    var heelPhase: CGFloat
    var motionPhase: CGFloat
    var hasCargo: Bool
    var cargoTaken: Bool
    var hazard: Bool
    var cleared: Bool

    func shift(at elapsed: CGFloat) -> CGFloat {
        guard kind == .movingLedge else { return 0 }
        return sin(motionPhase + elapsed * 1.15) * Physics.ledgeTravel * 0.5
    }

    func surface(at elapsed: CGFloat) -> CGFloat {
        guard kind == .drift else { return 0 }
        return sin(motionPhase + elapsed * 1.6) * Physics.driftAmp
    }

    func left(at elapsed: CGFloat) -> CGFloat {
        originX + shift(at: elapsed)
    }

    func right(at elapsed: CGFloat) -> CGFloat {
        left(at: elapsed) + deckWidth
    }
}

struct SimPulse: Sendable {
    var collected = false
    var hazard = false
    var landed = false
    var launched = false
    var failed = false
    var chapter = false
}

private struct BufferedJump {
    var power: CGFloat
    var at: CGFloat
}

private struct SeedMixer {
    var state: UInt64

    mutating func unit() -> CGFloat {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let bits = (state >> 33) & 0x7FFF_FFFF
        return CGFloat(bits) / CGFloat(0x7FFF_FFFF)
    }
}

/// Headless heel-sway runner. `FerryScene` copies this state. Tests call it with no view.
struct GameSimulation: Sendable {
    private(set) var seed: UInt64
    private var mixer: SeedMixer
    var body = BodyState()
    private(set) var chunks: [MooringBeat] = []
    private(set) var burden = 0
    private(set) var failed = false
    private(set) var phase: ReviewPose = .play
    private(set) var chapter = 1
    private(set) var chunksCleared = 0
    private(set) var collects = 0
    private(set) var refusedBeats = 0
    private(set) var elapsed: CGFloat = 0
    private(set) var heelPhase: CGFloat = 0.4
    private(set) var chapterLatch = false
    private(set) var tail: CGFloat = 0
    private var nextIndex = 0
    private var queuedPower: CGFloat?
    private var buffered: BufferedJump?
    private var finalHorn = false
    private var collectTimer: CGFloat = 0
    private var landTimer: CGFloat = 0

    init(seed: UInt64) {
        self.seed = seed == 0 ? 0x4D4F_4F52 : seed
        mixer = SeedMixer(state: self.seed)
        placePool()
    }

    static func fixedSeed() -> GameSimulation {
        var simulation = GameSimulation(seed: Physics.fixedSeed)
        simulation.clearOpeningGaps()
        return simulation
    }

    var score: Int {
        Int(body.x / 8) + collects * 40 + (chapter - 1) * 80
    }

    var nodeBudget: Int {
        NodeBudget.live(chunkCount: chunks.count)
    }

    var jumpFraction: CGFloat {
        guard Physics.jumpVelocity > 0 else { return 1 }
        return Physics.scaledVelocity(burden: burden) / Physics.jumpVelocity
    }

    var diagnostics: String {
        "x=\(body.x) y=\(body.y) cleared=\(chunksCleared) failed=\(failed) burden=\(burden) chunks=\(chunks.count) refused=\(refusedBeats)"
    }

    /// Flat reach is `runSpeed * (2 * jumpVelocity / gravity) * 0.85`, then heel trims the landing window.
    static func flatReach(burden: Int) -> CGFloat {
        let velocity = Physics.scaledVelocity(burden: burden)
        return Physics.runSpeed * (2 * velocity / Physics.gravity) * Physics.reachFactor
    }

    static func heelOffset(phase: CGFloat) -> CGFloat {
        abs(sin(phase)) * Physics.heelAmplitude
    }

    static func reachableEnvelope(burden: Int, heelPhase: CGFloat) -> CGFloat {
        max(0, flatReach(burden: burden) - heelOffset(phase: heelPhase))
    }

    static func reachable(gap: CGFloat, burden: Int, heelPhase: CGFloat) -> Bool {
        gap + 0.001 >= Physics.minGap && gap <= reachableEnvelope(burden: burden, heelPhase: heelPhase) + 0.001
    }

    /// Rejects a layout whose gap, including the heel window, sits outside the current envelope.
    mutating func refuseImpossibleBeat(maxGap: CGFloat, burden: Int, heelPhase: CGFloat) -> Bool {
        let refused = maxGap > Self.reachableEnvelope(burden: burden, heelPhase: heelPhase) + 0.001
        if refused {
            refusedBeats += 1
        }
        return refused
    }

    mutating func clearOpeningGaps() {
        var guardTime: CGFloat = 0
        while guardTime < 12, chunksCleared < 4, !failed {
            autoHopIfNeeded()
            _ = tick(Physics.fixedStep)
            guardTime += Physics.fixedStep
        }
    }

    mutating func releaseJump(power: CGFloat) {
        guard !failed, !chapterLatch else { return }
        let clamped = min(1, max(Physics.hopPower, power))
        if body.grounded {
            launch(clamped)
        } else {
            buffered = BufferedJump(power: clamped, at: elapsed)
        }
    }

    @discardableResult
    mutating func tick(_ raw: CGFloat) -> SimPulse {
        var pulse = SimPulse()
        let dt = min(max(raw, 0), 1 / 30)
        guard dt > 0, !failed, !chapterLatch else { return pulse }
        elapsed += dt
        heelPhase += dt * 0.85
        if body.grounded, let power = queuedPower {
            launch(power)
            pulse.launched = true
        }
        queuedPower = nil
        if body.grounded {
            rideDeck(dt)
        } else {
            integrateAir(dt, pulse: &pulse)
        }
        if resolveCargo() {
            pulse.collected = true
        }
        if resolveHazard() {
            pulse.hazard = true
            pulse.failed = true
        }
        recycleBehind()
        if noteChapter() {
            pulse.chapter = true
        }
        ageTimers(dt)
        return pulse
    }

    mutating func restart() {
        let kept = seed
        self = GameSimulation(seed: kept)
    }

    mutating func resumeFromChapter() {
        chapterLatch = false
        if phase == .chapter {
            phase = body.grounded ? .play : .air
        }
    }

    /// Contact queue from SpriteKit. Overlap checks stay in this type so a contact cannot double-count.
    mutating func applyContact(named name: String) -> SimPulse {
        var pulse = SimPulse()
        if name.contains("cargo"), resolveCargo() {
            pulse.collected = true
        }
        if name.contains("hazard"), !failed, resolveHazard() {
            pulse.hazard = true
            pulse.failed = true
        }
        return pulse
    }

    mutating func freeze(_ pose: ReviewPose) {
        phase = pose
        switch pose {
        case .play:
            body.x = 108
            body.y = 0
            body.vy = 0
            body.grounded = true
            elapsed = 0.35
        case .air:
            if let beat = chunks.first {
                body.x = beat.right(at: elapsed) - 36
            }
            body.y = 156
            body.vy = 280
            body.grounded = false
        case .land:
            body.x = 120
            body.y = 0
            body.vy = 0
            body.grounded = true
            landTimer = 0.18
        case .collect:
            burden = 1
            collects = 1
            body.x = 150
            body.y = 0
            body.grounded = true
            collectTimer = 0.28
            if !chunks.isEmpty {
                chunks[0].hasCargo = true
                chunks[0].cargoTaken = true
            }
        case .hazard:
            if !chunks.isEmpty {
                chunks[0].hazard = true
                let beat = chunks[0]
                body.x = beat.right(at: elapsed) + beat.gap * 0.42
            }
            body.y = 6
            body.vy = -40
            body.grounded = false
        case .fail:
            failed = true
            if let beat = chunks.first {
                body.x = beat.right(at: elapsed) + beat.gap * 0.5
            }
            body.y = -132
            body.vy = -220
            body.grounded = false
        case .pause:
            body.x = 108
            body.y = 0
            body.grounded = true
            elapsed = 0.5
        case .chapter:
            chapter = min(2, Physics.chapters)
            chapterLatch = true
            body.x = 108
            body.y = 0
            body.grounded = true
        }
    }

    private mutating func placePool() {
        chunks = []
        var cursor: CGFloat = 0
        for slot in 0..<Physics.poolCount {
            let beat = makeBeat(index: slot, origin: cursor, scripted: slot < 4)
            cursor = beat.originX + beat.deckWidth + beat.gap
            chunks.append(beat)
        }
        tail = cursor
        nextIndex = Physics.poolCount
    }

    private mutating func makeBeat(index: Int, origin: CGFloat, scripted: Bool) -> MooringBeat {
        let scriptedGaps: [CGFloat] = [80, 92, 108, 156]
        if scripted, index < scriptedGaps.count {
            return MooringBeat(
                index: index,
                originX: origin,
                deckWidth: Physics.deckWidth,
                gap: scriptedGaps[index],
                kind: .gap,
                heelPhase: 0.15 * CGFloat(index),
                motionPhase: 0,
                hasCargo: false,
                cargoTaken: false,
                hazard: false,
                cleared: false
            )
        }
        let roll = mixer.unit()
        var kind: ObstacleKind = .gap
        if roll > 0.72 {
            kind = .movingLedge
        } else if roll > 0.4 {
            kind = .drift
        }
        let phase = heelPhase
        let gap = legalGap(kind: kind, heelPhase: phase)
        let cargo = index > 4 && burden < Physics.maxBurden && mixer.unit() > 0.45
        let hazard = index > 5 && mixer.unit() > 0.55
        return MooringBeat(
            index: index,
            originX: origin,
            deckWidth: Physics.deckWidth,
            gap: gap,
            kind: kind,
            heelPhase: phase,
            motionPhase: mixer.unit() * 6.2,
            hasCargo: cargo,
            cargoTaken: false,
            hazard: hazard,
            cleared: false
        )
    }

    private mutating func legalGap(kind: ObstacleKind, heelPhase: CGFloat) -> CGFloat {
        let extra = Physics.placementExtra(kind: kind)
        let envelope = Self.reachableEnvelope(burden: burden, heelPhase: heelPhase)
        let cap = min(Physics.maxGap, envelope - extra)
        guard cap + 0.001 >= Physics.minGap else {
            refusedBeats += 1
            return Physics.minGap
        }
        let span = max(0, Physics.maxGap - Physics.minGap)
        let proposed = Physics.minGap + mixer.unit() * span
        if refuseImpossibleBeat(maxGap: proposed + extra, burden: burden, heelPhase: heelPhase) {
            return min(Physics.maxGap, max(Physics.minGap, cap))
        }
        return min(proposed, cap)
    }

    private mutating func autoHopIfNeeded() {
        guard body.grounded, queuedPower == nil else { return }
        guard let beat = deckAt( body.x) else { return }
        let distance = beat.right(at: elapsed) - body.x
        guard distance > 0, distance <= Physics.takeoffLead else { return }
        guard beat.gap > 24 else { return }
        queuedPower = 1
    }

    private mutating func launch(_ power: CGFloat) {
        body.vy = Physics.scaledVelocity(burden: burden) * power
        body.grounded = false
        body.y = 0.2
        phase = .air
        buffered = nil
    }

    private mutating func rideDeck(_ dt: CGFloat) {
        guard let beat = deckAt( body.x) else {
            body.grounded = false
            phase = .air
            return
        }
        body.vy = 0
        body.y = beat.surface(at: elapsed)
        body.x += Physics.runSpeed * dt
        if deckAt( body.x) == nil {
            body.grounded = false
            phase = .air
        } else if phase == .land || phase == .collect {
            if landTimer <= 0, collectTimer <= 0 {
                phase = .play
            }
        } else if phase != .pause, phase != .chapter {
            phase = .play
        }
    }

    private mutating func integrateAir(_ dt: CGFloat, pulse: inout SimPulse) {
        body.vy -= Physics.gravity * dt
        body.y += body.vy * dt
        body.x += Physics.runSpeed * dt
        guard body.vy < 0 else { return }
        if let beat = deckAt( body.x) {
            let deck = beat.surface(at: elapsed)
            if body.y <= deck + 1 {
                body.y = deck
                body.vy = 0
                body.grounded = true
                phase = .land
                landTimer = 0.16
                pulse.landed = true
                markCleared(beat)
                consumeBuffer(pulse: &pulse)
            }
        } else if body.y < -36 {
            failed = true
            phase = .fail
            pulse.failed = true
        }
    }

    private mutating func consumeBuffer(pulse: inout SimPulse) {
        guard let buffered else { return }
        self.buffered = nil
        if elapsed - buffered.at <= Physics.inputBuffer {
            launch(buffered.power)
            pulse.launched = true
        }
    }

    private mutating func markCleared(_ beat: MooringBeat) {
        guard beat.index >= 1, !beat.cleared else { return }
        guard let slot = chunks.firstIndex(where: { $0.index == beat.index }) else { return }
        chunks[slot].cleared = true
        chunksCleared += 1
    }

    private mutating func resolveCargo() -> Bool {
        guard burden < Physics.maxBurden else { return false }
        guard let slot = chunks.firstIndex(where: { beat in
            guard beat.hasCargo, !beat.cargoTaken else { return false }
            let cargoX = beat.left(at: elapsed) + beat.deckWidth * 0.58
            return abs(body.x - cargoX) < 22 && body.y < 46 && body.y > -4
        }) else { return false }
        chunks[slot].cargoTaken = true
        burden += 1
        collects += 1
        phase = .collect
        collectTimer = 0.28
        retileAhead()
        return true
    }

    /// Chunks the hero has not reached are rebuilt so a new burden cannot inherit an illegal gap.
    private mutating func retileAhead() {
        for slot in chunks.indices {
            let beat = chunks[slot]
            guard beat.left(at: elapsed) > body.x + 36 else { continue }
            let gap = legalGap(kind: beat.kind, heelPhase: heelPhase)
            chunks[slot].gap = gap
            chunks[slot].heelPhase = heelPhase
            if chunks[slot].hasCargo, burden >= Physics.maxBurden {
                chunks[slot].hasCargo = false
            }
        }
        rebuildTail()
    }

    private mutating func rebuildTail() {
        let ordered = chunks.sorted { $0.originX < $1.originX }
        var cursor = ordered.first?.originX ?? 0
        var origins: [Int: CGFloat] = [:]
        for beat in ordered {
            origins[beat.index] = cursor
            cursor += beat.deckWidth + beat.gap
        }
        for slot in chunks.indices {
            if let origin = origins[chunks[slot].index] {
                chunks[slot].originX = origin
            }
        }
        tail = cursor
    }

    private mutating func resolveHazard() -> Bool {
        for beat in chunks where beat.hazard {
            let hazardX = beat.right(at: elapsed) + beat.gap * 0.42
            let nearX = abs(body.x - hazardX) < 16
            let nearY = body.y < 32 && body.y > -6
            if nearX && nearY {
                failed = true
                phase = .hazard
                return true
            }
        }
        return false
    }

    private mutating func recycleBehind() {
        guard let oldest = chunks.enumerated().min(by: { $0.element.originX < $1.element.originX }) else { return }
        guard body.x > oldest.element.right(at: elapsed) + 460 else { return }
        let index = nextIndex
        nextIndex += 1
        let beat = makeBeat(index: index, origin: tail, scripted: false)
        tail = beat.originX + beat.deckWidth + beat.gap
        chunks[oldest.offset] = beat
    }

    private mutating func noteChapter() -> Bool {
        guard !chapterLatch else { return false }
        let gate = chapter * 6
        guard chunksCleared >= gate else { return false }
        if chapter < Physics.chapters {
            chapter += 1
            chapterLatch = true
            phase = .chapter
            return true
        }
        if !finalHorn {
            finalHorn = true
            chapterLatch = true
            phase = .chapter
            return true
        }
        return false
    }

    private mutating func ageTimers(_ dt: CGFloat) {
        if collectTimer > 0 {
            collectTimer = max(0, collectTimer - dt)
        }
        if landTimer > 0 {
            landTimer = max(0, landTimer - dt)
        }
    }

    private func deckAt(_ x: CGFloat) -> MooringBeat? {
        var found: MooringBeat?
        for beat in chunks {
            let left = beat.left(at: elapsed)
            let right = beat.right(at: elapsed)
            if x >= left, x <= right {
                if found == nil || beat.index > found!.index {
                    found = beat
                }
            }
        }
        return found
    }
}
