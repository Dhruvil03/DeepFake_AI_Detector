import SwiftUI

struct ResultCard: View {
    let result: AnalysisResult

    var verdictColor: Color {
        switch result.verdict {
        case .likelyAuthentic: return ProofyPalette.neonGreen
        case .likelySynthetic: return ProofyPalette.alertRed
        case .inconclusive: return ProofyPalette.neonAmber
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.verdict.label.uppercased())
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(1.5)
                    .foregroundStyle(verdictColor)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(verdictColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(verdictColor.opacity(0.3)))
                Spacer()
                Text("\(Int(result.confidence * 100))%")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(ProofyPalette.textPrimary)
            }

            ProgressView(value: result.confidence)
                .tint(verdictColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("ANALYSIS LOG")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(ProofyPalette.textTertiary)
                Text(result.reasoning)
                    .font(.system(size: 14))
                    .foregroundStyle(ProofyPalette.textSecondary)
            }
            .padding(12)
            .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ProofyPalette.glassBorder))

            if !result.flaggedIndicators.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FLAGGED INDICATORS")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(ProofyPalette.textTertiary)
                    ForEach(result.flaggedIndicators, id: \.self) { indicator in
                        Label(indicator, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(ProofyPalette.textSecondary)
                    }
                }
            }

            Text("AI-assisted estimate — not a certified forensic result.")
                .font(.caption2)
                .foregroundStyle(ProofyPalette.textTertiary)
        }
        .glassCard(cornerRadius: 24)
    }
}
