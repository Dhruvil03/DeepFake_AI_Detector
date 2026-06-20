import Foundation

enum TranscriptionError: LocalizedError {
    case invalidEndpoint
    case http(Int, String)
    case emptyResult
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "The transcription endpoint URL is invalid. Check it in Settings."
        case .http(let code, let body):
            return "Transcription server returned \(code): \(body.prefix(200))"
        case .emptyResult:
            return "Transcription returned no text."
        case .decoding(let err):
            return "Couldn't parse the transcription response: \(err.localizedDescription)"
        }
    }
}

/// Groq's chat completions API has no audio_url content type — audio support
/// is a separate Whisper-based /audio/transcriptions endpoint (speech-to-text
/// only, not acoustic/forensic reasoning). This client does the multipart
/// upload that endpoint expects, distinct from InferenceClient's JSON body.
actor TranscriptionClient {

    func transcribe(config: InferenceConfig, transcriptionEndpoint: String, modelName: String, audioFileURL: URL) async throws -> String {
        guard let url = URL(string: transcriptionEndpoint) else {
            throw TranscriptionError.invalidEndpoint
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if !config.apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 90

        let audioData = try Data(contentsOf: audioFileURL)
        request.httpBody = Self.buildMultipartBody(
            boundary: boundary,
            modelName: modelName,
            fileName: audioFileURL.lastPathComponent,
            fileData: audioData
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw TranscriptionError.http(0, "No HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw TranscriptionError.http(http.statusCode, bodyText)
        }

        struct TranscriptionResponse: Decodable { let text: String }
        do {
            let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            guard !decoded.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw TranscriptionError.emptyResult
            }
            return decoded.text
        } catch let error as TranscriptionError {
            throw error
        } catch {
            throw TranscriptionError.decoding(error)
        }
    }

    private static func buildMultipartBody(boundary: String, modelName: String, fileName: String, fileData: Data) -> Data {
        var body = Data()
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        appendField("model", modelName)
        appendField("response_format", "json")

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
