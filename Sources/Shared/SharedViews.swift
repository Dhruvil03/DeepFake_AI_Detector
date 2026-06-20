import SwiftUI

struct ContentPlaceholder: View {
    let systemImage: String
    let text: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(ProofyPalette.neonGreen.opacity(0.6))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(ProofyPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .glassCard()
    }
}
