import SwiftUI

struct SettingsSheetView: View {
    @ObservedObject var store: RunRecordStore
    var onReset: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DeckMetrics.space16) {
                Text("Best runs stay on this device.")
                    .font(DeckType.display(18))
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Link(destination: URL(string: "https://hawserrun-deck.pro/contact-us")!) {
                    Text("Contact")
                        .font(DeckType.display(18))
                        .foregroundStyle(DesignTokens.bg)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(DesignTokens.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DeckMetrics.button))
                }
                Button("Reset") {
                    store.resetAllData()
                    onReset()
                    dismiss()
                }
                .font(DeckType.display(18))
                .foregroundStyle(DesignTokens.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: DeckMetrics.button)
                        .stroke(DesignTokens.ink, lineWidth: DeckMetrics.hairline)
                )
                Spacer()
            }
            .padding(DeckMetrics.space24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DesignTokens.bg)
            .navigationTitle("Settings")
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
}
