import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var history: HistoryStore

    var body: some View {
        List {
            ForEach(history.items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.mediaKind.rawValue.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(ProofyPalette.neonGreen)
                        Spacer()
                        Text(item.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(ProofyPalette.textTertiary)
                    }
                    Text(item.verdict.label)
                        .font(.subheadline.bold())
                        .foregroundStyle(ProofyPalette.textPrimary)
                    Text(item.reasoning)
                        .font(.caption)
                        .foregroundStyle(ProofyPalette.textSecondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
                .listRowBackground(ProofyPalette.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .proofyBackground()
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear", role: .destructive) { history.clear() }
                    .disabled(history.items.isEmpty)
                    .tint(ProofyPalette.alertRed)
            }
        }
        .overlay {
            if history.items.isEmpty {
                ContentPlaceholder(systemImage: "clock", text: "No analyses yet")
                    .padding(.horizontal, 32)
            }
        }
    }
}
