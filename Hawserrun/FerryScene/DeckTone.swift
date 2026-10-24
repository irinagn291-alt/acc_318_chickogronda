import AVFoundation

/// Short synthesized cues. Buffers are scheduled on the existing player, not allocated per frame.
@MainActor
final class DeckTone {
    enum Cue {
        case jump
        case land
        case collect
        case hazard
        case horn
    }

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private var started = false

    init() {
        format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
            ?? AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.85
    }

    func play(_ cue: Cue) {
        guard ensure(), let buffer = render(cue) else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    private func ensure() -> Bool {
        if started {
            if !engine.isRunning {
                started = false
            } else {
                if !player.isPlaying {
                    player.play()
                }
                return true
            }
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            if !engine.isRunning {
                try engine.start()
            }
            if !player.isPlaying {
                player.play()
            }
            started = true
            return true
        } catch {
            started = false
            return false
        }
    }

    private func render(_ cue: Cue) -> AVAudioPCMBuffer? {
        let rate = format.sampleRate
        let seconds: Double
        switch cue {
        case .jump: seconds = 0.07
        case .land: seconds = 0.09
        case .collect: seconds = 0.16
        case .hazard: seconds = 0.28
        case .horn: seconds = 0.42
        }
        let frames = AVAudioFrameCount(max(1, rate * seconds))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        guard let samples = buffer.floatChannelData?[0] else { return nil }
        for index in 0..<Int(frames) {
            let t = Double(index) / rate
            let env = sin(.pi * min(1, t / seconds))
            let sample: Double
            switch cue {
            case .jump:
                let freq = 620 + 280 * (t / seconds)
                sample = sin(2 * .pi * freq * t) * env * 0.22
            case .land:
                let noise = sin(2 * .pi * 90 * t) * 0.35 + sin(2 * .pi * 240 * t * (1 + Double(index % 7) * 0.03))
                sample = noise * env * 0.18
            case .collect:
                let freq = 460 - 240 * (t / seconds)
                sample = sin(2 * .pi * freq * t) * env * 0.24
            case .hazard:
                let freq = 280 - 180 * (t / seconds)
                sample = sin(2 * .pi * freq * t) * env * 0.28
            case .horn:
                let body = sin(2 * .pi * 146 * t) + 0.55 * sin(2 * .pi * 220 * t)
                sample = body * env * 0.2
            }
            samples[index] = Float(max(-1, min(1, sample)))
        }
        return buffer
    }
}
