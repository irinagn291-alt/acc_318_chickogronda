import SwiftUI

struct PauseOverlayView: View {
    var onResume: () -> Void
    var onRecords: () -> Void
    var onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DeckMetrics.space12) {
            Text("Paused")
                .font(DeckType.display(28))
                .foregroundStyle(DesignTokens.ink)
            Text("The run is holding.")
                .font(DeckType.display(15))
                .foregroundStyle(DesignTokens.muted)
            DeckPlateButton(title: "Resume", filled: true, action: onResume)
            DeckPlateButton(title: "Records", filled: false, action: onRecords)
            DeckPlateButton(title: "Settings", filled: false, action: onSettings)
        }
        .padding(DeckMetrics.space16)
        .frame(maxWidth: 280, alignment: .leading)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: DeckMetrics.plate))
        .overlay(
            RoundedRectangle(cornerRadius: DeckMetrics.plate)
                .stroke(DesignTokens.ink, lineWidth: DeckMetrics.hairline)
        )
    }
}

private enum HornPhase: CaseIterable {
    case idle
    case swell
    case settle
}

struct ChapterOverlayView: View {
    var chapter: Int
    var score: Int
    var reduceMotion: Bool
    var onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DeckMetrics.space12) {
            chapterBanner
            Text(logLine)
                .font(DeckType.display(16))
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: DeckMetrics.space8) {
                Text("Score")
                    .font(DeckType.figure(13))
                    .foregroundStyle(DesignTokens.accent)
                Text(score, format: .number)
                    .font(DeckType.figure(13))
                    .foregroundStyle(DesignTokens.accent)
                    .contentTransition(.numericText(value: Double(score)))
            }
            DeckPlateButton(title: "Continue", filled: true, action: onContinue)
        }
        .padding(DeckMetrics.space16)
        .frame(maxWidth: 320, alignment: .leading)
        .background(DesignTokens.bg)
        .clipShape(RoundedRectangle(cornerRadius: DeckMetrics.plate))
        .overlay(
            RoundedRectangle(cornerRadius: DeckMetrics.plate)
                .stroke(DesignTokens.accent, lineWidth: DeckMetrics.hairline)
        )
    }

    private var logLine: String {
        switch chapter {
        case 2:
            return "Each crate cuts the jump. Short gaps still fit."
        case 3:
            return "The long gap clears only while you are light."
        case 4:
            return "Final horn. Weight still decides the leap."
        default:
            return "Tap hops. Hold, then release, for the long gap."
        }
    }

    @ViewBuilder
    private var chapterBanner: some View {
        let title = Text("Chapter \(chapter)")
            .font(DeckType.display(32))
            .foregroundStyle(DesignTokens.ink)
        if reduceMotion {
            title
        } else {
            PhaseAnimator([HornPhase.idle, HornPhase.swell, HornPhase.settle], trigger: chapter) { phase in
                title
                    .scaleEffect(phase == .swell ? 1.06 : 1)
                    .opacity(phase == .idle ? 0.86 : 1)
            }
        }
    }
}

struct DeckPlateButton: View {
    var title: String
    var filled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DeckType.display(18))
                .foregroundStyle(filled ? DesignTokens.bg : DesignTokens.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(filled ? DesignTokens.accent : DesignTokens.surface)
                .contentShape(Rectangle())
                .clipShape(RoundedRectangle(cornerRadius: DeckMetrics.button))
                .overlay(
                    RoundedRectangle(cornerRadius: DeckMetrics.button)
                        .stroke(filled ? DesignTokens.accent : DesignTokens.ink, lineWidth: DeckMetrics.hairline)
                )
        }
        .buttonStyle(.plain)
    }
}
