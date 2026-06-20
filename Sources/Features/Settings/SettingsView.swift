import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Inference Endpoint") {
                TextField("Endpoint URL", text: $settings.endpointURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Model name", text: $settings.modelName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("API key (optional)", text: $settings.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Stepper("Max tokens: \(settings.maxTokens)", value: $settings.maxTokens, in: 128...4096, step: 64)
            }
            .listRowBackground(ProofyPalette.surface)

            Section {
                Text("API key is only needed for endpoints that require auth (e.g. Groq's hosted API). Leave it blank for an unauthenticated self-hosted endpoint — no Authorization header is sent if it's empty.")
                    .font(.footnote)
                    .foregroundStyle(ProofyPalette.textSecondary)
            }
            .listRowBackground(ProofyPalette.surface)
        }
        .scrollContentBackground(.hidden)
        .proofyBackground()
        .navigationTitle("Settings")
    }
}
