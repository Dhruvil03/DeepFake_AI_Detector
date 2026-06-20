import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    FeatureCard(title: "Image Analysis", subtitle: "Detect AI-generated images", systemImage: "photo", color: ProofyPalette.neonGreen) {
                        ImageAnalysisView()
                    }
                    FeatureCard(title: "Video Analysis", subtitle: "Check video for inconsistencies", systemImage: "video", color: ProofyPalette.neonBlue) {
                        VideoAnalysisView()
                    }
                    FeatureCard(title: "Text Verification", subtitle: "Fact-check a claim", systemImage: "text.bubble", color: ProofyPalette.neonGreen) {
                        TextVerificationView()
                    }
                    FeatureCard(title: "Audio Analysis", subtitle: "Check for synthetic voice", systemImage: "waveform", color: ProofyPalette.neonBlue) {
                        AudioAnalysisView()
                    }
                }
                .padding()
            }
            .proofyBackground()
            .navigationTitle("DeepFake AI Detector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(ProofyPalette.neonGreen)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(ProofyPalette.neonGreen)
                    }
                }
            }
        }
    }
}

private struct FeatureCard<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3)))
                VStack(alignment: .leading) {
                    Text(title).font(.headline).foregroundStyle(ProofyPalette.textPrimary)
                    Text(subtitle).font(.subheadline).foregroundStyle(ProofyPalette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(ProofyPalette.textTertiary)
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}
