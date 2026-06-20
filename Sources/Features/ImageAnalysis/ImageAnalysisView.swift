import SwiftUI
import PhotosUI

@MainActor
final class ImageAnalysisViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isAnalyzing = false
    @Published var result: AnalysisResult?
    @Published var errorMessage: String?

    func analyze(settings: AppSettings, history: HistoryStore) async {
        guard let image = selectedImage, let dataURI = MediaEncoder.imageDataURI(image) else {
            errorMessage = "No image selected."
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
                systemPrompt: PromptTemplates.imageSystem,
                userText: "Analyze this image.",
                mediaBlocks: [.imageURL(dataURI)]
            )
            let parsed = AnalysisResult.parse(rawText: raw, mediaKind: .image)
            result = parsed
            history.add(parsed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ImageAnalysisView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var history: HistoryStore
    @StateObject private var viewModel = ImageAnalysisViewModel()
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ProofyPalette.glassBorder))
                } else {
                    ContentPlaceholder(systemImage: "photo", text: "Select an image to analyze")
                }

                PhotosPicker("Choose Image", selection: $pickerItem, matching: .images)
                    .buttonStyle(NeonSecondaryButtonStyle())

                Button {
                    Task { await viewModel.analyze(settings: settings, history: history) }
                } label: {
                    if viewModel.isAnalyzing {
                        ProgressView().tint(ProofyPalette.neonGreen)
                    } else {
                        Text("ANALYZE")
                    }
                }
                .buttonStyle(NeonButtonStyle(color: ProofyPalette.neonGreen))
                .disabled(viewModel.selectedImage == nil || viewModel.isAnalyzing)

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
        .navigationTitle("Image Analysis")
        .onChange(of: pickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    viewModel.selectedImage = uiImage
                    viewModel.result = nil
                }
            }
        }
    }
}
