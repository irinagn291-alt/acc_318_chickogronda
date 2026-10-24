import SpriteKit

/// Playable deck container. Chunks live here so the heel can tip the lane together.
@MainActor
final class DeckLane: SKNode {
    override init() {
        super.init()
        name = "deck"
        zPosition = 20
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }
}
