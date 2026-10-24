import SpriteKit
import UIKit

/// Chapter horn flare. It is a pooled node, not a second scene.
@MainActor
final class HornCue: SKNode {
    private let ring = SKShapeNode(circleOfRadius: 18)
    private var life: CGFloat = 0

    override init() {
        super.init()
        name = "horn"
        zPosition = 68
        ring.strokeColor = DesignTokens.accentUI
        ring.fillColor = DesignTokens.accentUI.withAlphaComponent(0.15)
        ring.lineWidth = 2
        ring.isHidden = true
        addChild(ring)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func sound() {
        life = 0.45
        ring.isHidden = false
        ring.setScale(0.4)
        ring.alpha = 1
    }

    func advance(_ dt: CGFloat) {
        guard life > 0 else { return }
        life = max(0, life - dt)
        let progress = 1 - (life / 0.45)
        ring.setScale(0.4 + progress * 1.8)
        ring.alpha = life / 0.45
        if life == 0 {
            ring.isHidden = true
        }
    }
}
