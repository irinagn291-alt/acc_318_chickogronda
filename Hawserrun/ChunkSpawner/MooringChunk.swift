import SpriteKit
import UIKit

/// One pooled deck plate. Gap space is open water, never a labeled tile.
@MainActor
final class MooringChunk: SKNode {
    let cargo = CargoCrate()
    private let deck = SKShapeNode()
    private let lip = SKShapeNode()
    private let wake = SKSpriteNode(color: DesignTokens.skyUI.withAlphaComponent(0.01), size: CGSize(width: 80, height: 14))
    private let hazard = SKShapeNode()
    private let cleat = SKShapeNode()

    override init() {
        super.init()
        name = "mooring"
        zPosition = 20
        deck.path = MooringChunk.deckPath(width: Physics.deckWidth)
        deck.fillColor = DesignTokens.groundUI
        deck.strokeColor = DesignTokens.inkUI
        deck.lineWidth = 1.25
        deck.zPosition = 1
        addChild(deck)
        lip.path = MooringChunk.lipPath(width: Physics.deckWidth)
        lip.fillColor = DesignTokens.midUI
        lip.strokeColor = .clear
        lip.zPosition = 2
        addChild(lip)
        wake.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        wake.zPosition = 0
        addChild(wake)
        hazard.path = MooringChunk.boomPath()
        hazard.fillColor = DesignTokens.hazardUI
        hazard.strokeColor = DesignTokens.inkUI
        hazard.lineWidth = 1
        hazard.zPosition = 50
        hazard.name = "hazard"
        addChild(hazard)
        cleat.path = MooringChunk.cleatPath()
        cleat.fillColor = DesignTokens.farUI
        cleat.strokeColor = DesignTokens.inkUI
        cleat.lineWidth = 1
        cleat.position = CGPoint(x: 36, y: 8)
        cleat.zPosition = 3
        addChild(cleat)
        cargo.zPosition = 4
        addChild(cargo)
        let sensor = SKPhysicsBody(rectangleOf: CGSize(width: 36, height: 52), center: CGPoint(x: 10, y: 28))
        sensor.isDynamic = false
        sensor.categoryBitMask = PhysicsCategory.hazard
        sensor.contactTestBitMask = PhysicsCategory.hero
        sensor.collisionBitMask = 0
        hazard.physicsBody = sensor
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func setChapter(_ chapter: Int) {
        switch chapter {
        case 2:
            lip.fillColor = DesignTokens.accentUI
            deck.fillColor = DesignTokens.groundUI
        case 3:
            lip.fillColor = DesignTokens.farUI
            deck.fillColor = DesignTokens.midUI
        case 4:
            lip.fillColor = DesignTokens.hazardUI
            deck.fillColor = DesignTokens.midUI
        default:
            lip.fillColor = DesignTokens.midUI
            deck.fillColor = DesignTokens.groundUI
        }
    }

    func apply(beat: MooringBeat, elapsed: CGFloat) {
        let width = beat.deckWidth
        wake.size = CGSize(width: max(8, beat.gap), height: 12)
        wake.position = CGPoint(x: width + beat.gap * 0.5, y: -18)
        wake.color = DesignTokens.midUI.withAlphaComponent(0.45)
        cargo.position = CGPoint(x: width * 0.58, y: 34)
        cargo.setAvailable(beat.hasCargo && !beat.cargoTaken)
        hazard.isHidden = !beat.hazard
        hazard.position = CGPoint(x: width + beat.gap * 0.42, y: 0)
        hazard.physicsBody?.categoryBitMask = beat.hazard ? PhysicsCategory.hazard : 0
        cleat.isHidden = false
        _ = elapsed
    }

    private static func deckPath(width: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: -58))
        path.addLine(to: CGPoint(x: width, y: -58))
        path.addLine(to: CGPoint(x: width - 6, y: 0))
        path.addLine(to: CGPoint(x: 6, y: 0))
        path.closeSubpath()
        return path
    }

    private static func lipPath(width: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 8, y: 0))
        path.addLine(to: CGPoint(x: width - 8, y: 0))
        path.addLine(to: CGPoint(x: width - 14, y: 7))
        path.addLine(to: CGPoint(x: 14, y: 7))
        path.closeSubpath()
        return path
    }

    private static func boomPath() -> CGPath {
        let path = CGMutablePath()
        path.addRect(CGRect(x: -5, y: 0, width: 10, height: 58))
        path.move(to: CGPoint(x: -5, y: 46))
        path.addLine(to: CGPoint(x: 42, y: 64))
        path.addLine(to: CGPoint(x: 42, y: 54))
        path.addLine(to: CGPoint(x: -5, y: 36))
        path.closeSubpath()
        path.addEllipse(in: CGRect(x: 34, y: 40, width: 14, height: 14))
        return path
    }

    private static func cleatPath() -> CGPath {
        let path = CGMutablePath()
        path.addRoundedRect(in: CGRect(x: -8, y: 0, width: 16, height: 6), cornerWidth: 1, cornerHeight: 1)
        path.move(to: CGPoint(x: -10, y: 6))
        path.addLine(to: CGPoint(x: 10, y: 6))
        path.addLine(to: CGPoint(x: 7, y: 10))
        path.addLine(to: CGPoint(x: -7, y: 10))
        path.closeSubpath()
        return path
    }
}
