import SwiftUI
import UIKit

extension DesignTokens {
    static var bgUI: UIColor { UIColor(bg) }
    static var surfaceUI: UIColor { UIColor(surface) }
    static var inkUI: UIColor { UIColor(ink) }
    static var accentUI: UIColor { UIColor(accent) }
    static var mutedUI: UIColor { UIColor(muted) }
    static var skyUI: UIColor { UIColor(sky) }
    static var farUI: UIColor { UIColor(far) }
    static var midUI: UIColor { UIColor(mid) }
    static var groundUI: UIColor { UIColor(ground) }
    static var heroUI: UIColor { UIColor(hero) }
    static var hazardUI: UIColor { UIColor(hazard) }
    static var collectibleUI: UIColor { UIColor(collectible) }
    static var weatherUI: UIColor { UIColor(weather) }
    static var shadowUI: UIColor { UIColor(shadow) }
}

enum DeckMetrics {
    static let plate: CGFloat = 20
    static let button: CGFloat = 24
    static let hud: CGFloat = 18
    static let hairline: CGFloat = 1
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space24: CGFloat = 24
}

/// One spring for presses, toggles, and the live score.
enum Motion {
    static let stateChange = Animation.spring(.snappy)
}

enum DeckType {
    static func display(_ size: CGFloat) -> Font {
        Font.custom(DesignTokens.fontFamily, size: size).italic()
    }

    static func uiFont(_ size: CGFloat, italic: Bool = false) -> UIFont {
        let names = italic
            ? ["HoeflerText-Italic", "Hoefler Text"]
            : ["HoeflerText-Regular", "Hoefler Text"]
        for name in names {
            if let font = UIFont(name: name, size: size) {
                return font
            }
        }
        return UIFont.systemFont(ofSize: size)
    }
}
