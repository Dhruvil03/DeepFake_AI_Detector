import Foundation

enum InferenceError: LocalizedError {
    case invalidEndpoint
    case http(Int, String)
    case emptyResponse
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "The inference endpoint URL is invalid. Check it in Settings."
        case .http(let code, let body):
            return "Server returned \(code): \(body.prefix(200))"
        case .emptyResponse:
            return "The model returned no content."
        case .decoding(let err):
            return "Couldn't parse the response: \(err.localizedDescription)"
        }
    }
}

/// Thin client for the self-hosted OpenAI-compatible /v1/chat/completions endpoint.
actor InferenceClient {

    func complete(
        config: InferenceConfig,
        systemPrompt: String,
        userText: String,
        mediaBlocks: [ContentBlock] = []
    ) async throws -> String {
        guard let url = URL(string: config.endpointURL) else {
            throw InferenceError.invalidEndpoint
        }

        var content: [ContentBlock] = [.text(userText)]
        content.append(contentsOf: mediaBlocks)

        let messages: [ChatMessage] = [
            ChatMessage(role: "system", content: [.text(systemPrompt)]),
            ChatMessage(role: "user", content: content)
        ]

        let body = ChatCompletionRequest(
            model: config.modelName,
            messages: messages,
            maxTokens: config.maxTokens
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 150

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw InferenceError.http(0, "No HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw InferenceError.http(http.statusCode, bodyText)
        }

        do {
            let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            guard let text = decoded.choices.first?.message.content, !text.isEmpty else {
                throw InferenceError.emptyResponse
            }
            return text
        } catch {
            throw InferenceError.decoding(error)
        }
    }
}
