import Foundation

/// Snapshot of endpoint config passed into the actor, so we don't capture
/// a main-actor ObservableObject from a background actor context.
struct InferenceConfig: Sendable {
    let endpointURL: String
    let modelName: String
    let maxTokens: Int
    let apiKey: String
}

struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, messages
        case maxTokens = "max_tokens"
    }
}

struct ChatMessage: Encodable {
    let role: String
    let content: [ContentBlock]
}

/// Mirrors the OpenAI-compatible content-block schema your endpoint accepts,
/// e.g. {"type": "video_url", "video_url": {"url": "data:video/mp4;base64,..."}}
enum ContentBlock: Encodable, Sendable {
    case text(String)
    case imageURL(String)
    case videoURL(String)
    case audioURL(String)

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageURL = "image_url"
        case videoURL = "video_url"
        case audioURL = "audio_url"
    }
    private struct URLWrapper: Encodable { let url: String }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode("text", forKey: .type)
            try container.encode(value, forKey: .text)
        case .imageURL(let url):
            try container.encode("image_url", forKey: .type)
            try container.encode(URLWrapper(url: url), forKey: .imageURL)
        case .videoURL(let url):
            try container.encode("video_url", forKey: .type)
            try container.encode(URLWrapper(url: url), forKey: .videoURL)
        case .audioURL(let url):
            try container.encode("audio_url", forKey: .type)
            try container.encode(URLWrapper(url: url), forKey: .audioURL)
        }
    }
}

struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String?
            let reasoningContent: String?
            enum CodingKeys: String, CodingKey {
                case role, content
                case reasoningContent = "reasoning_content"
            }
        }
        let message: Message
        let finishReason: String?
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    let choices: [Choice]
}
