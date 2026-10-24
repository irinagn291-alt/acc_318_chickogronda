import SpriteKit
import UIKit

/// Loads `hsr_` imagesets and draws a stand-in when the texture is still empty.
enum DeckTextures {
    static let backdropFar = "BackdropFar"
    static let backdropMid = "BackdropMid"
    static let collectible = "Collectible"
    static let propNear = "PropNear"
    static let propFar = "PropFar"

    static func texture(stem: String) -> SKTexture {
        let catalog = "hsr_\(stem)"
        if let image = UIImage(named: catalog), image.size.width > 1, image.size.height > 1 {
            return SKTexture(image: image)
        }
        return SKTexture(image: procedural(stem))
    }

    static func procedural(_ stem: String) -> UIImage {
        let canvas = stem == backdropFar || stem == backdropMid
        let size = canvas ? CGSize(width: 1024, height: 512) : CGSize(width: 256, height: 256)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = canvas
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let ctx = context.cgContext
            if canvas {
                let sky = stem == backdropFar ? UIColor(DesignTokens.sky) : UIColor(DesignTokens.mid)
                sky.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
                let hill = stem == backdropFar ? UIColor(DesignTokens.far) : UIColor(DesignTokens.ground)
                hill.setFill()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: size.height * 0.28))
                path.addLine(to: CGPoint(x: size.width * 0.18, y: size.height * 0.62))
                path.addLine(to: CGPoint(x: size.width * 0.34, y: size.height * 0.4))
                path.addLine(to: CGPoint(x: size.width * 0.52, y: size.height * 0.7))
                path.addLine(to: CGPoint(x: size.width * 0.7, y: size.height * 0.36))
                path.addLine(to: CGPoint(x: size.width * 0.86, y: size.height * 0.58))
                path.addLine(to: CGPoint(x: size.width, y: size.height * 0.3))
                path.addLine(to: CGPoint(x: size.width, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.closeSubpath()
                ctx.addPath(path)
                ctx.fillPath()
            } else {
                ctx.clear(CGRect(origin: .zero, size: size))
                let fill: UIColor
                switch stem {
                case collectible:
                    fill = UIColor(DesignTokens.collectible)
                case propNear:
                    fill = UIColor(DesignTokens.weather)
                default:
                    fill = UIColor(DesignTokens.far)
                }
                fill.setFill()
                UIColor(DesignTokens.ink).setStroke()
                ctx.setLineWidth(6)
                let inset = CGRect(x: 48, y: 48, width: 160, height: 150)
                if stem == collectible {
                    ctx.addRect(inset)
                    ctx.drawPath(using: .fillStroke)
                } else if stem == propNear {
                    ctx.move(to: CGPoint(x: 128, y: 36))
                    ctx.addLine(to: CGPoint(x: 78, y: 210))
                    ctx.addLine(to: CGPoint(x: 178, y: 210))
                    ctx.closePath()
                    ctx.drawPath(using: .fillStroke)
                } else {
                    ctx.addEllipse(in: CGRect(x: 70, y: 40, width: 116, height: 170))
                    ctx.drawPath(using: .fillStroke)
                }
            }
        }
    }
}
