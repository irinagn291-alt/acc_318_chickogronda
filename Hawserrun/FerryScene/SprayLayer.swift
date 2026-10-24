import SpriteKit
import UIKit

/// Foreground weather. The emitter is created once and aimed at the scene.
@MainActor
final class SprayLayer: SKNode {
    let emitter = SKEmitterNode()
    private let puffTexture: SKTexture

    override init() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor(DesignTokens.weather).withAlphaComponent(0.9).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        puffTexture = SKTexture(image: image)
        super.init()
        name = "spray"
        zPosition = 60
        emitter.particleTexture = puffTexture
        emitter.particleBirthRate = 10
        emitter.particleLifetime = 1.3
        emitter.particleSpeed = 36
        emitter.particleSpeedRange = 18
        emitter.particleAlpha = 0.45
        emitter.particleAlphaSpeed = -0.3
        emitter.particleScale = 0.35
        emitter.particleScaleRange = 0.2
        emitter.particleColor = DesignTokens.weatherUI
        emitter.particleColorBlendFactor = 1
        emitter.emissionAngle = .pi
        emitter.emissionAngleRange = 0.4
        emitter.particlePositionRange = CGVector(dx: 80, dy: 20)
        emitter.zPosition = 60
        addChild(emitter)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func attach(to scene: SKScene, viewSize: CGSize) {
        emitter.targetNode = scene
        emitter.particlePositionRange = CGVector(dx: max(200, viewSize.width), dy: 24)
        emitter.position = CGPoint(x: 0, y: viewSize.height * 0.42)
    }
}
