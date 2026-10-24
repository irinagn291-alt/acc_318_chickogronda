import SwiftUI

struct ChapterBuoy: View {
    var chapter: Int
    var reduceMotion: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("CH")
                .font(DeckType.display(12))
                .tracking(1.2)
                .foregroundStyle(DesignTokens.muted)
            Text(chapter, format: .number)
                .font(DeckType.figure(16))
                .foregroundStyle(DesignTokens.ink)
                .contentTransition(.numericText(value: Double(chapter)))
                .animation(reduceMotion ? nil : Motion.stateChange, value: chapter)
        }
        .frame(width: 44, height: 44)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: DeckMetrics.hud))
        .overlay(
            RoundedRectangle(cornerRadius: DeckMetrics.hud)
                .stroke(DesignTokens.accent.opacity(0.9), lineWidth: DeckMetrics.hairline)
        )
        .accessibilityLabel("Chapter")
        .accessibilityValue(Text(chapter, format: .number))
    }
}
