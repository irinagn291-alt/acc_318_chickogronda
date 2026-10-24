import SwiftUI

@MainActor
final class DeckChrome: ObservableObject {
    @Published var chapter = 1
    @Published var score = 0
    @Published var cargo = 0
    @Published var heel = 0.0
    @Published var burdenFraction = 0.0
    @Published var paused = false
    @Published var showChapter = false
    @Published var cargoCommit = 0

    func noteCargo() {
        cargoCommit += 1
    }
}

struct HeelGauge: View {
    var burdenFraction: Double
    var heel: Double
    var score: Int
    var reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("HEEL")
                    .font(DeckType.display(12))
                    .tracking(1.4)
                    .foregroundStyle(DesignTokens.muted)
                Spacer()
                Text(score, format: .number)
                    .font(DeckType.figure(13))
                    .foregroundStyle(DesignTokens.ink)
                    .contentTransition(.numericText(value: Double(score)))
                    .animation(reduceMotion ? nil : Motion.stateChange, value: score)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DesignTokens.bg)
                    Capsule()
                        .fill(DesignTokens.accent)
                        .frame(width: max(6, geo.size.width * burdenFraction))
                        .animation(reduceMotion ? nil : Motion.stateChange, value: burdenFraction)
                    Circle()
                        .fill(DesignTokens.ink)
                        .frame(width: 7, height: 7)
                        .offset(x: (geo.size.width - 7) * (0.5 + heel * 0.5))
                }
                .overlay(Capsule().stroke(DesignTokens.ink.opacity(0.85), lineWidth: DeckMetrics.hairline))
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: DeckMetrics.hud))
        .overlay(
            RoundedRectangle(cornerRadius: DeckMetrics.hud)
                .stroke(DesignTokens.ink.opacity(0.8), lineWidth: DeckMetrics.hairline)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Heel and cargo")
        .accessibilityValue(Text(score, format: .number))
    }
}

extension DeckType {
    static func figure(_ size: CGFloat) -> Font {
        Font.system(size: size, weight: .semibold, design: .monospaced)
    }
}
