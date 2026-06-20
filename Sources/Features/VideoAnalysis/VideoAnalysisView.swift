import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

@MainActor
final class VideoAnalysisViewModel: ObservableObject {
    @Published var videoURL: URL?
    @Published var isAnalyzing = false
    @Published var result: AnalysisResult?
    @Published var errorMessage: String?

    func analyze(settings: AppSettings, history: HistoryStore) async {
        guard let url = videoURL else {
            errorMessage = "No video selected."
            return
        }
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            // Groq's chat completions API has no video_url content type, so
            // we extract evenly-spaced frames client-side and send them as
            // a sequence of image_url blocks instead of the whole video file.
            let frames = try await MediaEncoder.extractFrames(from: url, maxFrames: settings.videoFrameCount)
            guard !frames.isEmpty else {
                errorMessage = "Couldn't extract any frames from this video."
                return
            }
            let frameBlocks: [ContentBlock] = frames.compactMap { frame in
                MediaEncoder.imageDataURI(frame).map { .imageURL($0) }
            }

            let client = InferenceClient()
            let config = InferenceConfig(
                endpointURL: settings.endpointURL,
                modelName: settings.modelName,
                maxTokens: settings.maxTokens,
                apiKey: settings.apiKey
            )
            let raw = try await client.complete(
                config: config,
                systemPrompt: PromptTemplates.videoFrameSystem,
                userText: "These are \(frameBlocks.count) frames sampled evenly across a video, in chronological order. Analyze them for signs of AI generation or manipulation.",
                mediaBlocks: frameBlocks
            )
            let parsed = AnalysisResult.parse(rawText: raw, mediaKind: .video)
            result = parsed
            history.add(parsed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct VideoAnalysisView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var history: HistoryStore
    @StateObject private var viewModel = VideoAnalysisViewModel()
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let url = viewModel.videoURL {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ProofyPalette.glassBorder))
                } else {
                    ContentPlaceholder(systemImage: "video", text: "Select a video to analyze")
                }

                PhotosPicker("Choose Video", selection: $pickerItem, matching: .videos)
                    .buttonStyle(NeonSecondaryButtonStyle())

                Text("Frames are sampled from the video and analyzed as a sequence of images — large videos still take longer to process.")
                    .font(.caption)
                    .foregroundStyle(ProofyPalette.textTertiary)

                Button {
                    Task { await viewModel.analyze(settings: settings, history: history) }
                } label: {
                    if viewModel.isAnalyzing {
                        ProgressView().tint(ProofyPalette.neonBlue)
                    } else {
                        Text("ANALYZE")
                    }
                }
                .buttonStyle(NeonButtonStyle(color: ProofyPalette.neonBlue))
                .disabled(viewModel.videoURL == nil || viewModel.isAnalyzing)

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
        .navigationTitle("Video Analysis")
        .onChange(of: pickerItem) { newItem in
            Task {
                if let movie = try? await newItem?.loadTransferable(type: VideoTransfer.self) {
                    viewModel.videoURL = movie.url
                    viewModel.result = nil
                }
            }
        }
    }
}

/// Copies the picked video into a stable temp URL we can re-read for base64 encoding.
struct VideoTransfer: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { SentTransferredFile($0.url) } importing: { received in
            let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
            try FileManager.default.copyItem(at: received.file, to: dest)
            return Self(url: dest)
        }
    }
}
