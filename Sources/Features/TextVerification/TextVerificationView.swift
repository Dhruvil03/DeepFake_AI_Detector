import SwiftUI

@MainActor
final class TextVerificationViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isAnalyzing = false
    @Published var result: AnalysisResult?
    @Published var errorMessage: String?

    func analyze(settings: AppSettings, history: HistoryStore) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Enter some text first."
            return
        }
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        let client = InferenceClient()
        let config = InferenceConfig(
            endpointURL: settings.endpointURL,
            modelName: settings.modelName,
            maxTokens: settings.maxTokens,
            apiKey: settings.apiKey
        )
        do {
            let raw = try await client.complete(
                config: config,
                systemPrompt: PromptTemplates.textSystem,
                userText: "Claim to evaluate:\n\n\(trimmed)"
            )
            let parsed = AnalysisResult.parse(rawText: raw, mediaKind: .text)
            result = parsed
            history.add(parsed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TextVerificationView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var history: HistoryStore
    @StateObject private var viewModel = TextVerificationViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                TextEditor(text: $viewModel.inputText)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(ProofyPalette.textPrimary)
                    .frame(height: 140)
                    .padding(8)
                    .background(ProofyPalette.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(ProofyPalette.glassBorder))

                Button {
                    Task { await viewModel.analyze(settings: settings, history: history) }
                } label: {
                    if viewModel.isAnalyzing {
                        ProgressView().tint(ProofyPalette.neonGreen)
                    } else {
                        Text("VERIFY")
                    }
                }
                .buttonStyle(NeonButtonStyle(color: ProofyPalette.neonGreen))
                .disabled(viewModel.isAnalyzing)

                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(ProofyPalette.alertRed).font(.footnote)
                }
                if let result = viewModel.result {
                    ResultCard(result: result)
                }
            }
            .padding()
        }
        .proofyBackground()
        .navigationTitle("Text Verification")
    }
}
