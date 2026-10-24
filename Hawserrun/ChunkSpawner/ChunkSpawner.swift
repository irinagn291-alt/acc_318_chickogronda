import SpriteKit

/// Fixed pool of deck chunks. `sync` only moves nodes that already exist.
@MainActor
final class ChunkSpawner {
    private(set) var nodes: [MooringChunk] = []

    func install(into parent: SKNode) {
        guard nodes.isEmpty else { return }
        for _ in 0..<Physics.poolCount {
            let chunk = MooringChunk()
            nodes.append(chunk)
            parent.addChild(chunk)
        }
    }

    func sync(beats: [MooringBeat], floorY: CGFloat, bob: CGFloat, elapsed: CGFloat, heel: CGFloat) {
        for (slot, beat) in beats.enumerated() where slot < nodes.count {
            let chunk = nodes[slot]
            chunk.isHidden = false
            chunk.position = CGPoint(x: beat.left(at: elapsed), y: floorY + beat.surface(at: elapsed) + bob)
            chunk.zRotation = sin(heel + beat.heelPhase) * 0.03
            chunk.apply(beat: beat, elapsed: elapsed)
        }
    }
}
