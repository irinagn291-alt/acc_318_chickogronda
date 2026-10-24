import SpriteKit
import UIKit

/// Articulated deck runner: body, wing, leg, and a face. The shadow is a sibling, not a child.
@MainActor
final class HeroNode: SKNode {
    private let body = SKShapeNode()
    private let tail = SKShapeNode()
    private let limb = SKShapeNode()
    private let leg = SKShapeNode()
    private let face = SKNode()
    private let head = SKShapeNode()
    private let beak = SKShapeNode()
    private let comb = SKShapeNode()
    private let eye = SKShapeNode()
    private let loadMarks: [SKShapeNode]
    private let readScale: CGFloat = 2.45
    private var runPhase: CGFloat = 1.2

    override init() {
        loadMarks = (0..<Physics.maxBurden).map { index in
            let mark = SKShapeNode(rectOf: CGSize(width: 8, height: 7), cornerRadius: 1.5)
            mark.fillColor = DesignTokens.collectibleUI
            mark.strokeColor = DesignTokens.inkUI
            mark.lineWidth = 0.8
            mark.position = CGPoint(x: -14 - CGFloat(index) * 7, y: 18 + CGFloat(index) * 2)
            mark.isHidden = true
            mark.zPosition = 2
            return mark
        }
        super.init()
        name = "hero"
        zPosition = 40
        addShape(body, path: HeroNode.bodyPath(), fill: DesignTokens.heroUI, to: self)
        addShape(tail, path: HeroNode.tailPath(), fill: DesignTokens.groundUI, to: self)
        addShape(limb, path: HeroNode.wingPath(), fill: DesignTokens.inkUI, to: self)
        addShape(leg, path: HeroNode.legPath(), fill: DesignTokens.midUI, to: self)
        addShape(head, path: HeroNode.headPath(), fill: DesignTokens.heroUI, to: face)
        addShape(beak, path: HeroNode.beakPath(), fill: DesignTokens.accentUI, to: face)
        addShape(comb, path: HeroNode.combPath(), fill: DesignTokens.hazardUI, to: face)
        addShape(eye, path: CGPath(ellipseIn: CGRect(x: 6.5, y: 2, width: 3.2, height: 3.2), transform: nil), fill: DesignTokens.inkUI, to: face)
        limb.position = CGPoint(x: -2, y: 16)
        limb.zPosition = 3
        leg.position = CGPoint(x: 2, y: 2)
        leg.zPosition = 1
        face.position = CGPoint(x: 8, y: 30)
        face.zPosition = 4
        addChild(face)
        for mark in loadMarks {
            addChild(mark)
        }
        let bodySensor = SKPhysicsBody(rectangleOf: CGSize(width: 26, height: 36), center: CGPoint(x: 2, y: 20))
        bodySensor.affectedByGravity = false
        bodySensor.allowsRotation = false
        bodySensor.linearDamping = 0
        bodySensor.friction = 0
        bodySensor.restitution = 0
        bodySensor.categoryBitMask = PhysicsCategory.hero
        bodySensor.contactTestBitMask = PhysicsCategory.cargo | PhysicsCategory.hazard
        bodySensor.collisionBitMask = 0
        physicsBody = bodySensor
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func setCrouch(_ crouched: Bool) {
        limb.zRotation = crouched ? 0.8 : limb.zRotation
    }

    func sync(
        pose: ReviewPose,
        altitude: CGFloat,
        vy: CGFloat,
        burden: Int,
        dt: CGFloat,
        squash: CGFloat,
        stretch: CGFloat
    ) {
        if pose == .play || pose == .pause || pose == .chapter {
            runPhase += dt * 13
            limb.zRotation = sin(runPhase) * 0.75
            leg.zRotation = -sin(runPhase) * 0.5
        } else if pose == .air {
            limb.zRotation = -1.05
            leg.zRotation = 0.55
        } else if pose == .hazard {
            limb.zRotation = -1.25
            leg.zRotation = 0.95
        } else if pose == .fail {
            limb.zRotation = 1.45
            leg.zRotation = 1.15
        } else {
            limb.zRotation = 0.25
            leg.zRotation = 0.12
        }
        let aim = atan2(vy, Physics.runSpeed)
        face.zRotation = aim * 0.28
        eye.position = CGPoint(x: 6.2 + sin(aim) * 0.8, y: 2.2)
        for (index, mark) in loadMarks.enumerated() {
            mark.isHidden = index >= burden
        }
        zRotation = pose == .fail ? 1.4 : (pose == .hazard ? -0.9 : 0)
        let wide: CGFloat
        let tall: CGFloat
        if stretch > 0.01 {
            wide = 1 - 0.1 * stretch
            tall = 1 + 0.18 * stretch
        } else if squash > 0.01 {
            wide = 1 + 0.16 * squash
            tall = 1 - 0.2 * squash
        } else {
            wide = 1
            tall = 1
        }
        let blend: CGFloat = dt == 0 ? 1 : min(1, dt * 9)
        xScale += (readScale * wide - xScale) * blend
        yScale += (readScale * tall - yScale) * blend
        _ = altitude
    }

    private func addShape(_ node: SKShapeNode, path: CGPath, fill: UIColor, to parent: SKNode) {
        node.path = path
        node.fillColor = fill
        node.strokeColor = DesignTokens.inkUI
        node.lineWidth = 1.2
        node.zPosition = 2
        parent.addChild(node)
    }

    private static func bodyPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -16, y: 8))
        path.addCurve(to: CGPoint(x: 10, y: 6), control1: CGPoint(x: -18, y: 28), control2: CGPoint(x: 4, y: 34))
        path.addCurve(to: CGPoint(x: 16, y: 10), control1: CGPoint(x: 18, y: 14), control2: CGPoint(x: 20, y: 8))
        path.addCurve(to: CGPoint(x: -16, y: 8), control1: CGPoint(x: 8, y: -2), control2: CGPoint(x: -8, y: -2))
        path.closeSubpath()
        return path
    }

    private static func tailPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -14, y: 16))
        path.addLine(to: CGPoint(x: -26, y: 26))
        path.addLine(to: CGPoint(x: -22, y: 14))
        path.addLine(to: CGPoint(x: -28, y: 12))
        path.addLine(to: CGPoint(x: -16, y: 10))
        path.closeSubpath()
        return path
    }

    private static func wingPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addCurve(to: CGPoint(x: 18, y: -2), control1: CGPoint(x: 8, y: 8), control2: CGPoint(x: 16, y: 4))
        path.addCurve(to: CGPoint(x: 2, y: -8), control1: CGPoint(x: 14, y: -8), control2: CGPoint(x: 6, y: -10))
        path.closeSubpath()
        return path
    }

    private static func legPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -2, y: 8))
        path.addLine(to: CGPoint(x: -1, y: 0))
        path.addLine(to: CGPoint(x: 7, y: -1))
        path.addLine(to: CGPoint(x: 7, y: 2))
        path.addLine(to: CGPoint(x: 2, y: 2))
        path.addLine(to: CGPoint(x: 3, y: 8))
        path.closeSubpath()
        return path
    }

    private static func headPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -6, y: -2))
        path.addCurve(to: CGPoint(x: 8, y: 0), control1: CGPoint(x: -4, y: 10), control2: CGPoint(x: 8, y: 10))
        path.addCurve(to: CGPoint(x: -6, y: -2), control1: CGPoint(x: 6, y: -6), control2: CGPoint(x: -2, y: -6))
        path.closeSubpath()
        return path
    }

    private static func beakPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 6, y: 1))
        path.addLine(to: CGPoint(x: 16, y: 0))
        path.addLine(to: CGPoint(x: 6, y: -3))
        path.closeSubpath()
        return path
    }

    private static func combPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -2, y: 6))
        path.addLine(to: CGPoint(x: 0, y: 12))
        path.addLine(to: CGPoint(x: 3, y: 6))
        path.addLine(to: CGPoint(x: 5, y: 11))
        path.addLine(to: CGPoint(x: 7, y: 5))
        path.closeSubpath()
        return path
    }
}

/// Ground shadow. Kept out of the body so it stays on the deck while the runner rises.
@MainActor
final class DeckShadowNode: SKNode {
    private let blot = SKShapeNode(ellipseOf: CGSize(width: 74, height: 16))

    override init() {
        super.init()
        name = "shadow"
        zPosition = 30
        blot.fillColor = DesignTokens.shadowUI
        blot.strokeColor = .clear
        blot.alpha = 0.85
        addChild(blot)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func sync(altitude: CGFloat) {
        let lift = min(1, max(0, altitude / 100))
        blot.xScale = max(0.22, 1 - lift * 0.78)
        blot.yScale = max(0.35, 1 - lift * 0.55)
        blot.alpha = max(0.1, 0.9 - lift * 0.8)
    }
}

enum PhysicsCategory {
    static let hero: UInt32 = 1 << 0
    static let cargo: UInt32 = 1 << 1
    static let hazard: UInt32 = 1 << 2
}
