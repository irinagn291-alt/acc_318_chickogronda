import SpriteKit
import UIKit

/// Rope-side crate. Texture name is Collectible, with a drawn crate when the imageset is empty.
@MainActor
final class CargoCrate: SKNode {
    private let plate = SKSpriteNode()
    private let strap = SKShapeNode()

    override init() {
        super.init()
        name = "cargo"
        zPosition = 22
        plate.texture = DeckTextures.texture(stem: DeckTextures.collectible)
        plate.size = CGSize(width: 28, height: 28)
        plate.zPosition = 0
        addChild(plate)
        let band = CGMutablePath()
        band.move(to: CGPoint(x: -10, y: -12))
        band.addLine(to: CGPoint(x: -10, y: 12))
        band.move(to: CGPoint(x: 6, y: -12))
        band.addLine(to: CGPoint(x: 6, y: 12))
        strap.path = band
        strap.strokeColor = DesignTokens.inkUI
        strap.lineWidth = 1.4
        strap.zPosition = 1
        addChild(strap)
        let sensor = SKPhysicsBody(rectangleOf: CGSize(width: 24, height: 24))
        sensor.isDynamic = false
        sensor.categoryBitMask = PhysicsCategory.cargo
        sensor.contactTestBitMask = PhysicsCategory.hero
        sensor.collisionBitMask = 0
        physicsBody = sensor
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func setAvailable(_ available: Bool) {
        isHidden = !available
        physicsBody?.categoryBitMask = available ? PhysicsCategory.cargo : 0
    }
}
