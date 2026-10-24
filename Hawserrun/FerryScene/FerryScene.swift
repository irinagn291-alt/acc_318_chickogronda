import SpriteKit
import UIKit

/// Horizontal ferry deck. The scene renders `GameSimulation` and does not integrate a second time.
@MainActor
final class FerryScene: SKScene, SKPhysicsContactDelegate {
    private var sim: GameSimulation
    private let hero = HeroNode()
    private let shadow = DeckShadowNode()
    private let lane = DeckLane()
    private let hawser = HawserLayer()
    private let spray = SprayLayer()
    private let horn = HornCue()
    private let tone = DeckTone()
    private let spawner = ChunkSpawner()
    private let cameraNode = SKCameraNode()
    private let goal = SKLabelNode(fontNamed: DeckType.uiFont(20, italic: true).fontName)
    private let hint = SKLabelNode(fontNamed: DeckType.uiFont(15, italic: true).fontName)
    private var farPlates: [SKSpriteNode] = []
    private var farProps: [SKSpriteNode] = []
    private var nearProps: [SKSpriteNode] = []
    private var puffs: [SKShapeNode] = []
    private var splashes: [SKShapeNode] = []
    private var strikes: [SKShapeNode] = []
    private let wash = SKSpriteNode(color: DesignTokens.midUI, size: CGSize(width: 8, height: 8))
    private var contacts: [(String?, String?)] = []
    private var chrome: DeckChrome?
    private var store: RunRecordStore?
    private var reviewPose: ReviewPose?
    private var lastUpdateTime: TimeInterval = 0
    private var accumulator: CGFloat = 0
    private var hitStop: CGFloat = 0
    private var trauma: CGFloat = 0
    private var stretch: CGFloat = 0
    private var squash: CGFloat = 0
    private var cameraSmooth: CGFloat = 0
    private var hudStamp: TimeInterval = 0
    private var puffCursor = 0
    private var built = false
    private var frozen = false
    private var playerPaused = false
    private var failArmed = false
    private var holding = false
    private var pressBegan: TimeInterval = 0
    private var reduceMotion = false
    private var pendingScore = 0
    private var pendingChapter = 1
    private var pendingCargo = 0

    override init(size: CGSize) {
        sim = GameSimulation(seed: UInt64(Date().timeIntervalSince1970 * 1000) | 1)
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = DesignTokens.farUI
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func bind(chrome: DeckChrome, store: RunRecordStore) {
        self.chrome = chrome
        self.store = store
        if let screen = ReviewLaunch.screen, let pose = ReviewPose(rawValue: screen) {
            reviewPose = pose
            chrome.paused = pose == .pause
            chrome.showChapter = pose == .chapter
            if pose == .chapter {
                chrome.chapter = 2
            }
        }
    }

    func togglePause() {
        guard !frozen, !sim.chapterLatch, !failArmed else { return }
        setPaused(!playerPaused)
    }

    func setPaused(_ paused: Bool) {
        guard !frozen else { return }
        playerPaused = paused
        chrome?.paused = paused
    }

    func dismissChapter() {
        guard !frozen else { return }
        sim.resumeFromChapter()
        chrome?.showChapter = false
    }

    func reloadFerryScene(saving: Bool) {
        if saving {
            store?.noteFinishedRun(score: sim.score, chapter: sim.chapter, cargo: sim.burden)
        }
        sim.restart()
        accumulator = 0
        hitStop = 0
        trauma = 0
        stretch = 0
        squash = 0
        failArmed = false
        playerPaused = false
        holding = false
        chrome?.paused = false
        chrome?.showChapter = false
        if built {
            layoutWorld(dt: 0)
            pushHud(force: true)
        }
    }

    nonisolated override func didMove(to view: SKView) {
        MainActor.assumeIsolated {
            self.attach()
        }
    }

    nonisolated override func didChangeSize(_ oldSize: CGSize) {
        MainActor.assumeIsolated {
            guard self.built else { return }
            self.layoutWorld(dt: 0)
        }
    }

    nonisolated override func update(_ currentTime: TimeInterval) {
        MainActor.assumeIsolated {
            self.advance(currentTime)
        }
    }

    nonisolated override func didFinishUpdate() {
        MainActor.assumeIsolated {
            self.hero.physicsBody?.velocity = .zero
        }
    }

    nonisolated override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        MainActor.assumeIsolated {
            self.beginTouch()
        }
    }

    nonisolated override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        MainActor.assumeIsolated {
            self.endTouch()
        }
    }

    nonisolated override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        MainActor.assumeIsolated {
            self.endTouch()
        }
    }

    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        let nameA = contact.bodyA.node?.name
        let nameB = contact.bodyB.node?.name
        MainActor.assumeIsolated {
            self.contacts.append((nameA, nameB))
        }
    }

    private func attach() {
        guard !built else { return }
        built = true
        reduceMotion = UIAccessibility.isReduceMotionEnabled
        addChild(lane)
        spawner.install(into: lane)
        addChild(hawser)
        addChild(shadow)
        addChild(hero)
        addChild(cameraNode)
        camera = cameraNode
        installPlates()
        installPuffs()
        installCues()
        configureCopy()
        cameraNode.addChild(goal)
        cameraNode.addChild(hint)
        cameraNode.addChild(spray)
        cameraNode.addChild(horn)
        spray.attach(to: self, viewSize: size)
        if let pose = reviewPose {
            sim.freeze(pose)
            frozen = true
            if pose == .land || pose == .collect {
                squash = 1
            }
            if pose == .chapter {
                horn.sound()
            }
            layoutWorld(dt: 0)
            if pose == .land || pose == .collect {
                showPuff(at: CGPoint(x: sim.body.x, y: floorY + 8))
            }
            pushHud(force: true)
        } else {
            layoutWorld(dt: 0)
            pushHud(force: true)
        }
    }

    private func advance(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : min(currentTime - lastUpdateTime, 1.0 / 30.0)
        lastUpdateTime = currentTime
        if frozen {
            return
        }
        if hitStop > 0 {
            hitStop -= dt
            if failArmed, hitStop <= 0 {
                let score = pendingScore
                let chapter = pendingChapter
                let cargo = pendingCargo
                failArmed = false
                store?.noteFinishedRun(score: score, chapter: chapter, cargo: cargo)
                reloadFerryScene(saving: false)
            }
            return
        }
        if playerPaused {
            layoutWorld(dt: 0)
            return
        }
        accumulator += dt
        let step = Physics.fixedStep
        var slices = 0
        var pulse = SimPulse()
        while accumulator >= step, slices < 2 {
            let slice = sim.tick(step)
            pulse.collected = pulse.collected || slice.collected
            pulse.hazard = pulse.hazard || slice.hazard
            pulse.landed = pulse.landed || slice.landed
            pulse.launched = pulse.launched || slice.launched
            pulse.failed = pulse.failed || slice.failed
            pulse.chapter = pulse.chapter || slice.chapter
            accumulator -= step
            slices += 1
        }
        if slices == 2, accumulator > 0 {
            accumulator = 0
        }
        drainContacts(into: &pulse)
        if pulse.launched {
            stretch = 1
        }
        if pulse.landed || pulse.collected {
            squash = 1
        }
        if pulse.collected || pulse.hazard {
            hitStop = Physics.hitStop
            trauma = pulse.hazard ? 1 : min(1, trauma + 0.4)
        }
        if pulse.collected {
            chrome?.noteCargo()
            tone.play(.collect)
        }
        if pulse.launched {
            tone.play(.jump)
        }
        if pulse.landed {
            tone.play(.land)
        }
        if pulse.failed {
            armFail()
            hitStop = max(hitStop, Physics.hitStop)
            tone.play(.hazard)
        }
        if pulse.chapter {
            horn.sound()
            tone.play(.horn)
            chrome?.showChapter = true
            chrome?.chapter = sim.chapter
            store?.noteFinishedRun(score: sim.score, chapter: sim.chapter, cargo: sim.burden)
        }
        layoutWorld(dt: dt)
        if pulse.landed || pulse.collected {
            showPuff(at: CGPoint(x: sim.body.x, y: floorY + 6))
        }
        pushHud(force: pulse.chapter || pulse.failed || pulse.collected)
    }

    private func drainContacts(into pulse: inout SimPulse) {
        let pending = contacts
        contacts.removeAll(keepingCapacity: true)
        for pair in pending {
            for name in [pair.0, pair.1].compactMap({ $0 }) {
                let hit = sim.applyContact(named: name)
                pulse.collected = pulse.collected || hit.collected
                pulse.hazard = pulse.hazard || hit.hazard
                pulse.failed = pulse.failed || hit.failed
            }
        }
    }

    private func layoutWorld(dt: CGFloat) {
        let bob = sin(sim.heelPhase) * 8
        let deckY = floorY + bob
        let altitude = sim.phase == .fail ? min(sim.body.y, -132) : sim.body.y
        let sunk = sim.phase == .fail || altitude < -48
        shadow.isHidden = sunk
        hero.position = CGPoint(x: sim.body.x, y: deckY + altitude)
        shadow.position = CGPoint(x: sim.body.x, y: deckY + 2)
        shadow.sync(altitude: max(0, altitude))
        if stretch > 0 {
            stretch = max(0, stretch - dt * 4.5)
        }
        if squash > 0 {
            squash = max(0, squash - dt * 5)
        }
        hero.sync(
            pose: sim.phase,
            altitude: sim.body.y,
            vy: sim.body.vy,
            burden: sim.burden,
            dt: dt,
            squash: squash,
            stretch: stretch
        )
        spawner.sync(beats: sim.chunks, floorY: floorY, bob: bob, elapsed: sim.elapsed, heel: sim.heelPhase)
        for chunk in spawner.nodes {
            chunk.setChapter(sim.chapter)
        }
        easeCamera(dt: dt)
        hawser.layout(cameraX: cameraNode.position.x, floorY: floorY, heel: sim.heelPhase)
        layoutParallax()
        horn.advance(dt)
        fadePuffs(dt)
        layoutCaption()
        spray.emitter.particlePositionRange = CGVector(dx: max(220, size.width), dy: 28)
        spray.emitter.particleBirthRate = reduceMotion ? 0 : 8 + CGFloat(sim.chapter) * 4
        spray.emitter.particleAlpha = sim.chapter >= 4 ? 0.7 : 0.42
        horn.position = CGPoint(x: 0, y: size.height * 0.16)
        tintHorizon()
        layoutCues(deckY: deckY)
    }

    private func tintHorizon() {
        let tint: UIColor
        let blend: CGFloat
        switch sim.chapter {
        case 2:
            tint = DesignTokens.accentUI
            blend = 0.18
        case 3:
            tint = DesignTokens.farUI
            blend = 0.42
        case 4:
            tint = DesignTokens.hazardUI
            blend = 0.28
        default:
            tint = DesignTokens.skyUI
            blend = 0
        }
        for plate in farPlates {
            plate.color = tint
            plate.colorBlendFactor = blend
        }
    }

    /// Goal and gesture sit under the heel gauge, on the sky, with the deck still in view.
    private func layoutCaption() {
        let showing = sim.phase == .play && sim.elapsed < 9 && !playerPaused && !sim.chapterLatch
        goal.isHidden = !showing
        hint.isHidden = !showing
        guard showing else { return }
        let measure = min(max(180, size.width - 36), 340)
        let topInset = size.height > 500 ? max(150, size.height * 0.17) : 102
        let goalY = size.height * 0.5 - topInset
        goal.position = CGPoint(x: 0, y: goalY)
        hint.position = CGPoint(x: 0, y: goalY - 28)
        goal.preferredMaxLayoutWidth = measure
        hint.preferredMaxLayoutWidth = measure
    }

    private func easeCamera(dt: CGFloat) {
        let look = min(150, max(88, size.width * 0.28))
        var target = sim.body.x + look
        let half = max(120, size.width * 0.5)
        let maxCenter = max(half, sim.tail - size.width * 0.42)
        target = min(max(target, half), maxCenter)
        if cameraSmooth == 0 {
            cameraSmooth = target
        }
        let blend: CGFloat = dt == 0 ? 1 : min(1, dt * 7)
        cameraSmooth += (target - cameraSmooth) * blend
        var shakeX: CGFloat = 0
        var shakeY: CGFloat = 0
        if !reduceMotion, trauma > 0 {
            let mag = trauma * trauma * 5
            let sign: CGFloat = Bool.random() ? 1 : -1
            shakeX = sign * mag
            shakeY = CGFloat.random(in: -1...1) * mag * 0.55
            trauma = max(0, trauma - dt * 1.6)
        }
        // The deck sits on the harbor waterline. Sky above it is the same scene, not a second picture.
        let deckFraction: CGFloat = size.height > size.width ? 0.36 : 0.32
        let deckFromBottom = size.height * deckFraction
        let cameraY = floorY + size.height * 0.5 - deckFromBottom
        cameraNode.position = CGPoint(x: cameraSmooth + shakeX, y: cameraY + shakeY)
    }

    private func layoutParallax() {
        let cameraX = cameraNode.position.x
        let cameraY = cameraNode.position.y
        fitPlates()
        cover(
            farPlates,
            cameraX: cameraX,
            cameraY: cameraY,
            factor: 0.12,
            z: 1
        )
        placeMarks()
        let waterline = floorY - cameraY + 10
        spray.position = CGPoint(x: 0, y: waterline)
    }

    private func placeMarks() {
        let beat = sim.chunks.first
        let gapX = beat.map { $0.right(at: sim.elapsed) + $0.gap * 0.45 } ?? cameraNode.position.x
        let deckX = beat?.left(at: sim.elapsed) ?? sim.body.x
        if farProps.count > 1 {
            farProps[0].position = CGPoint(x: gapX - 30, y: floorY + 46)
            farProps[0].zPosition = 16
            farProps[1].position = CGPoint(x: gapX + 30, y: floorY + 52)
            farProps[1].zPosition = 16
        }
        if nearProps.count > 1 {
            nearProps[0].position = CGPoint(x: deckX + 186, y: floorY + 2)
            nearProps[0].zPosition = 28
            nearProps[1].position = CGPoint(x: deckX + 226, y: floorY + 2)
            nearProps[1].zPosition = 28
        }
    }

    /// The harbor plate is larger than the lens on both axes, so the sunset meets every edge.
    private func cover(
        _ nodes: [SKSpriteNode],
        cameraX: CGFloat,
        cameraY: CGFloat,
        factor: CGFloat,
        z: CGFloat
    ) {
        guard let plate = nodes.first, plate.size.width > 1, plate.size.height > 1 else { return }
        let slack = max(0, plate.size.width - size.width)
        let raw = cameraX * (1 - factor)
        let shift = min(slack * 0.45, max(-slack * 0.45, raw.truncatingRemainder(dividingBy: max(slack, 1))))
        plate.position = CGPoint(
            x: cameraX - plate.size.width * 0.5 + shift,
            y: cameraY
        )
        plate.zPosition = z
        if nodes.count > 1 {
            let spare = nodes[1]
            spare.position = CGPoint(
                x: plate.position.x + plate.size.width,
                y: plate.position.y
            )
            spare.zPosition = z
            spare.isHidden = true
        }
    }

    private func fitPlates() {
        guard let far = farPlates.first else { return }
        let farSize = coverSize(
            texture: far.texture,
            filling: CGSize(width: size.width * 1.2, height: size.height * 1.2)
        )
        for plate in farPlates {
            plate.size = farSize
        }
        let ring = CGSize(width: 64, height: 64)
        for prop in farProps {
            prop.size = ring
        }
        let bollard = CGSize(width: 36, height: 52)
        for prop in nearProps {
            prop.size = bollard
        }
    }

    private func coverSize(texture: SKTexture?, filling view: CGSize) -> CGSize {
        let tex = texture?.size() ?? CGSize(width: 1, height: 1)
        let aspect = max(0.2, tex.width / max(tex.height, 1))
        var width = view.width
        var height = width / aspect
        if height < view.height {
            height = view.height
            width = height * aspect
        }
        return CGSize(width: width, height: height)
    }

    private func installPlates() {
        farPlates = pair(stem: DeckTextures.backdropFar, size: CGSize(width: 32, height: 32), z: 1)
        farProps = pair(stem: DeckTextures.propFar, size: CGSize(width: 64, height: 64), z: 16)
        nearProps = pair(stem: DeckTextures.propNear, size: CGSize(width: 36, height: 52), z: 32)
        for node in farPlates + farProps + nearProps {
            addChild(node)
        }
        // The mid imageset is loaded for the world kit. It is not drawn as a poster.
        _ = DeckTextures.texture(stem: DeckTextures.backdropMid)
    }

    private func pair(stem: String, size: CGSize, z: CGFloat) -> [SKSpriteNode] {
        (0..<2).map { _ in
            let sprite = SKSpriteNode(texture: DeckTextures.texture(stem: stem))
            sprite.size = size
            sprite.zPosition = z
            sprite.anchorPoint = CGPoint(x: 0, y: 0.5)
            return sprite
        }
    }

    private func installPuffs() {
        for index in 0..<4 {
            let puff = SKShapeNode(circleOfRadius: 9 + CGFloat(index) * 2)
            puff.fillColor = DesignTokens.weatherUI
            puff.strokeColor = .clear
            puff.alpha = 0
            puff.isHidden = true
            puff.name = "dust"
            puff.zPosition = 46
            puffs.append(puff)
            addChild(puff)
        }
    }

    private func installCues() {
        wash.color = DesignTokens.midUI
        wash.alpha = 0.62
        wash.isHidden = true
        wash.zPosition = 43
        addChild(wash)
        for index in 0..<3 {
            let ripple = SKShapeNode(ellipseOf: CGSize(width: 34 + CGFloat(index) * 22, height: 12))
            ripple.fillColor = DesignTokens.weatherUI.withAlphaComponent(0.35)
            ripple.strokeColor = DesignTokens.weatherUI
            ripple.lineWidth = 2
            ripple.isHidden = true
            ripple.name = "splash"
            ripple.zPosition = 52
            splashes.append(ripple)
            addChild(ripple)
        }
        for index in 0..<3 {
            let hit = SKShapeNode(rectOf: CGSize(width: 5, height: 18 + CGFloat(index) * 8), cornerRadius: 1)
            hit.zRotation = CGFloat(index - 1) * 0.9
            hit.fillColor = DesignTokens.hazardUI
            hit.strokeColor = DesignTokens.inkUI
            hit.lineWidth = 1
            hit.isHidden = true
            hit.name = "strike"
            hit.zPosition = 60
            strikes.append(hit)
            addChild(hit)
        }
    }

    private func layoutCues(deckY: CGFloat) {
        let failing = sim.phase == .fail
        let striking = sim.phase == .hazard
        let surface = deckY - 8
        wash.isHidden = !failing
        if failing {
            let beat = sim.chunks.first { beat in
                let gapStart = beat.right(at: sim.elapsed)
                return sim.body.x >= gapStart - 8 && sim.body.x <= gapStart + beat.gap + 8
            } ?? sim.chunks.first
            let width = max(72, beat?.gap ?? 80)
            let center = beat.map { $0.right(at: sim.elapsed) + $0.gap * 0.5 } ?? sim.body.x
            wash.anchorPoint = CGPoint(x: 0.5, y: 1)
            wash.size = CGSize(width: width + 12, height: max(220, size.height * 0.62))
            wash.position = CGPoint(x: center, y: surface)
            wash.zPosition = 43
        }
        for (index, ripple) in splashes.enumerated() {
            ripple.isHidden = !failing
            if failing {
                ripple.position = CGPoint(x: sim.body.x + CGFloat(index - 1) * 26, y: surface + 2)
                ripple.zPosition = 52
            }
        }
        for (index, hit) in strikes.enumerated() {
            hit.isHidden = !striking
            if striking {
                hit.position = CGPoint(
                    x: sim.body.x + CGFloat(index - 1) * 14,
                    y: deckY + sim.body.y + 28 + CGFloat(index) * 12
                )
                hit.zPosition = 60
            }
        }
    }

    private func showPuff(at point: CGPoint) {
        guard !puffs.isEmpty else { return }
        let offsets = [
            CGPoint(x: -16, y: 6),
            CGPoint(x: 0, y: 14),
            CGPoint(x: 18, y: 4),
            CGPoint(x: 8, y: 18),
        ]
        for (index, offset) in offsets.enumerated() {
            let puff = puffs[(puffCursor + index) % puffs.count]
            puff.position = CGPoint(x: point.x + offset.x, y: point.y + offset.y)
            puff.isHidden = false
            puff.alpha = 0.92
            puff.setScale(1.15 + CGFloat(index) * 0.12)
        }
        puffCursor += offsets.count
    }

    private func fadePuffs(_ dt: CGFloat) {
        for puff in puffs where !puff.isHidden {
            puff.alpha -= dt * 2.4
            puff.setScale(puff.xScale + dt * 1.6)
            if puff.alpha <= 0.02 {
                puff.isHidden = true
            }
        }
    }

    private func configureCopy() {
        styleCue(goal, text: "Cross to the next horn", size: 20, lines: 1)
        styleCue(hint, text: "Tap hops. Hold, then release, for a long gap.", size: 15, lines: 2)
    }

    private func styleCue(_ label: SKLabelNode, text: String, size: CGFloat, lines: Int) {
        let shadow = NSShadow()
        shadow.shadowColor = UIColor(white: 0, alpha: 0.9)
        shadow.shadowOffset = CGSize(width: 0, height: 1)
        shadow.shadowBlurRadius = 3
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 72
        label.numberOfLines = lines
        label.lineBreakMode = .byWordWrapping
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: DeckType.uiFont(size, italic: true),
                .foregroundColor: DesignTokens.inkUI,
                .shadow: shadow,
            ]
        )
    }

    private func beginTouch() {
        guard !frozen, !playerPaused, !sim.chapterLatch, !failArmed else { return }
        holding = true
        pressBegan = CACurrentMediaTime()
        hero.setCrouch(true)
    }

    private func endTouch() {
        guard holding else { return }
        holding = false
        let held = max(0, CACurrentMediaTime() - pressBegan)
        sim.releaseJump(power: Self.charge(held))
    }

    private static func charge(_ held: TimeInterval) -> CGFloat {
        if held < 0.16 {
            return Physics.hopPower
        }
        let span = min(1, (held - 0.16) / 0.42)
        return Physics.hopPower + (1 - Physics.hopPower) * CGFloat(span)
    }

    private func armFail() {
        guard !failArmed else { return }
        failArmed = true
        pendingScore = sim.score
        pendingChapter = sim.chapter
        pendingCargo = sim.burden
    }

    private func pushHud(force: Bool) {
        let now = CACurrentMediaTime()
        guard force || now - hudStamp > 0.1 else { return }
        hudStamp = now
        chrome?.chapter = sim.chapter
        chrome?.score = sim.score
        chrome?.cargo = sim.burden
        chrome?.heel = Double(sin(sim.heelPhase))
        chrome?.burdenFraction = Double(sim.burden) / Double(Physics.maxBurden)
        if let pose = reviewPose {
            chrome?.paused = pose == .pause
            chrome?.showChapter = pose == .chapter
        } else {
            chrome?.paused = playerPaused
        }
    }

    private var floorY: CGFloat {
        136
    }
}
