import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

@MainActor
final class AudioAnalysisViewModel: NSObject, ObservableObject {
    @Published var audioURL: URL?
    @Published var isAnalyzing = false
    @Published var isRecording = false
    @Published var result: AnalysisResult?
    @Published var errorMessage: String?
    @Published var transcript: String?
    @Published var statusText: String?

    private var recorder: AVAudioRecorder?

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            audioURL = url
            isRecording = true
        } catch {
            errorMessage = "Couldn't start recording: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        recorder?.stop()
        isRecording = false
    }

    /// Groq's chat completions API has no audio_url content type — there's no
    /// direct acoustic/forensic reasoning over raw audio the way Nemotron
    /// Omni or Gemma 4's audio tower did. This is now a two-step pipeline:
    /// transcribe via Whisper, then run text-based content analysis on the
    /// transcript. This can no longer detect synthetic *voice* artifacts
    /// (prosody, spectral signal) — only whether the *words* raise flags.
    func analyze(settings: AppSettings, history: HistoryStore) async {
        guard let url = audioURL else {
            errorMessage = "No audio selected or recorded."
            return
        }
        isAnalyzing = true
        errorMessage = nil
        transcript = nil
        statusText = "Transcribing audio..."
        defer { isAnalyzing = false; statusText = nil }

        do {
            let transcriptionClient = TranscriptionClient()
            let config = InferenceConfig(
                endpointURL: settings.endpointURL,
                modelName: settings.modelName,
                maxTokens: settings.maxTokens,
                apiKey: settings.apiKey
            )
            let transcribedText = try await transcriptionClient.transcribe(
                config: config,
                transcriptionEndpoint: settings.transcriptionEndpointURL,
                modelName: settings.transcriptionModelName,
                audioFileURL: url
            )
            transcript = transcribedText
            statusText = "Analyzing transcript..."

            let client = InferenceClient()
            let raw = try await client.complete(
                config: config,
                systemPrompt: PromptTemplates.audioSystem,
                userText: "Transcript to evaluate:\n\n\(transcribedText)"
            )
            let parsed = AnalysisResult.parse(rawText: raw, mediaKind: .audio)
            result = parsed
            history.add(parsed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AudioAnalysisView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var history: HistoryStore
    @StateObject private var viewModel = AudioAnalysisViewModel()
    @State private var showImporter = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ContentPlaceholder(
                    systemImage: "waveform",
                    text: viewModel.audioURL?.lastPathComponent ?? "No audio selected"
                )

                HStack(spacing: 12) {
                    Button(viewModel.isRecording ? "Stop Recording" : "Record") {
                        viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
                    }
                    .buttonStyle(NeonSecondaryButtonStyle())

                    Button("Import File") { showImporter = true }
                        .buttonStyle(NeonSecondaryButtonStyle())
                }

                Text("Audio is transcribed first, then the transcript is analyzed for content red flags — this checks what was said, not how it sounds, so it can't detect synthetic-voice artifacts directly.")
                    .font(.caption)
                    .foregroundStyle(ProofyPalette.textTertiary)

                Button {
                    Task { await viewModel.analyze(settings: settings, history: history) }
                } label: {
                    if viewModel.isAnalyzing {
                        HStack(spacing: 8) {
                            ProgressView().tint(ProofyPalette.neonBlue)
                            if let status = viewModel.statusText {
                                Text(status)
                            }
                        }
                    } else {
                        Text("ANALYZE")
                    }
                }
                .buttonStyle(NeonButtonStyle(color: ProofyPalette.neonBlue))
                .disabled(viewModel.audioURL == nil || viewModel.isAnalyzing)

                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(ProofyPalette.alertRed).font(.footnote)
                }

                if let transcript = viewModel.transcript {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TRANSCRIPT")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(ProofyPalette.textTertiary)
                        Text(transcript)
                            .font(.caption)
                            .foregroundStyle(ProofyPalette.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
                }

                if let result = viewModel.result {
                    ResultCard(result: result)
                }
            }
            .padding()
        }
        .proofyBackground()
        .navigationTitle("Audio Analysis")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio]) { res in
            if case .success(let url) = res { viewModel.audioURL = url }
        }
    }
}
