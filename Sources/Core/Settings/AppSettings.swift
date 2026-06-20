import Foundation
import Combine

/// Stores the inference endpoint configuration. Defaults point at Groq's
/// hosted OpenAI-compatible API (api.groq.com) — real TLS, no ATS workaround
/// needed, but requires an API key.
final class AppSettings: ObservableObject {
    @Published var endpointURL: String {
        didSet { UserDefaults.standard.set(endpointURL, forKey: Keys.endpoint) }
    }
    @Published var transcriptionEndpointURL: String {
        didSet { UserDefaults.standard.set(transcriptionEndpointURL, forKey: Keys.transcriptionEndpoint) }
    }
    @Published var modelName: String {
        didSet { UserDefaults.standard.set(modelName, forKey: Keys.model) }
    }
    /// Whisper model used for the audio transcription step (see TranscriptionClient).
    @Published var transcriptionModelName: String {
        didSet { UserDefaults.standard.set(transcriptionModelName, forKey: Keys.transcriptionModel) }
    }
    @Published var maxTokens: Int {
        didSet { UserDefaults.standard.set(maxTokens, forKey: Keys.maxTokens) }
    }
    /// Groq (or any endpoint requiring auth) needs a Bearer API key on every
    /// request. Editable in the in-app Settings screen — left blank, no
    /// Authorization header is sent (fine for an unauthenticated self-hosted
    /// endpoint). Stored in UserDefaults for development convenience; move
    /// to Keychain before sharing this build with anyone else, since this
    /// can be a real billable credential.
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: Keys.apiKey) }
    }
    /// How many evenly-spaced frames to extract per video for analysis,
    /// since Groq's chat completions API has no video_url content type.
    @Published var videoFrameCount: Int {
        didSet { UserDefaults.standard.set(videoFrameCount, forKey: Keys.videoFrameCount) }
    }

    private enum Keys {
        static let endpoint = "proofy.endpointURL"
        static let transcriptionEndpoint = "proofy.transcriptionEndpointURL"
        static let model = "proofy.modelName"
        static let transcriptionModel = "proofy.transcriptionModelName"
        static let maxTokens = "proofy.maxTokens"
        static let apiKey = "proofy.apiKey"
        static let videoFrameCount = "proofy.videoFrameCount"
    }

    init() {
        let defaults = UserDefaults.standard
        self.endpointURL = defaults.string(forKey: Keys.endpoint)
            ?? "https://api.groq.com/openai/v1/chat/completions"
        self.transcriptionEndpointURL = defaults.string(forKey: Keys.transcriptionEndpoint)
            ?? "https://api.groq.com/openai/v1/audio/transcriptions"
        self.modelName = defaults.string(forKey: Keys.model)
            ?? "meta-llama/llama-4-maverick-17b-128e-instruct"
        self.transcriptionModelName = defaults.string(forKey: Keys.transcriptionModel)
            ?? "whisper-large-v3"
        self.maxTokens = defaults.object(forKey: Keys.maxTokens) as? Int ?? 1024
        self.apiKey = defaults.string(forKey: Keys.apiKey) ?? ""
        self.videoFrameCount = defaults.object(forKey: Keys.videoFrameCount) as? Int ?? 6
    }
}
