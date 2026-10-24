import SpriteKit
import UIKit

/// Hawser cables tiled from a fixed pool. Update only repositions them.
@MainActor
final class HawserLayer: SKNode {
    private let strands: [SKShapeNode]

    override init() {
        strands = (0..<6).map { index in
            let node = SKShapeNode(rectOf: CGSize(width: 180, height: 3), cornerRadius: 1)
            node.fillColor = index.isMultiple(of: 2) ? DesignTokens.accentUI : DesignTokens.inkUI
            node.strokeColor = .clear
            node.alpha = 0.85
            node.zPosition = 15
            return node
        }
        super.init()
        name = "hawser"
        zPosition = 15
        for strand in strands {
            addChild(strand)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func layout(cameraX: CGFloat, floorY: CGFloat, heel: CGFloat) {
        let span: CGFloat = 220
        let shift = -(cameraX * 0.15).truncatingRemainder(dividingBy: span)
        for (index, strand) in strands.enumerated() {
            let row = CGFloat(index % 2)
            strand.position = CGPoint(
                x: cameraX + shift + CGFloat(index) * 90 - 220,
                y: floorY + 58 + row * 18 + sin(heel + CGFloat(index)) * 6
            )
            strand.zRotation = sin(heel * 0.5 + CGFloat(index)) * 0.08
        }
    }
}
