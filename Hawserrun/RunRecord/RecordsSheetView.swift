import SwiftUI

struct RecordsSheetView: View {
    @ObservedObject var store: RunRecordStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DeckMetrics.space16) {
                recordLine("Best score", value: store.record.bestScore)
                recordLine("Highest chapter", value: store.record.highestChapter)
                recordLine("Peak cargo", value: store.record.peakCargo)
                Spacer()
            }
            .padding(DeckMetrics.space24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DesignTokens.bg)
            .navigationTitle("Records")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                        .font(DeckType.display(16))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func recordLine(_ title: String, value: Int) -> some View {
        HStack {
            Text(title)
                .font(DeckType.display(18))
                .foregroundStyle(DesignTokens.ink)
            Spacer()
            Text(value, format: .number)
                .font(DeckType.figure(18))
                .foregroundStyle(DesignTokens.accent)
                .contentTransition(.numericText(value: Double(value)))
        }
        .padding(.vertical, DeckMetrics.space8)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DesignTokens.ink.opacity(0.35))
                .frame(height: DeckMetrics.hairline)
        }
    }
}
