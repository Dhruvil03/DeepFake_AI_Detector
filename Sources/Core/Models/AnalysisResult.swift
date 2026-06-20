import Foundation

enum MediaKind: String, Codable { case image, video, text, audio }

enum Verdict: String, Codable {
    case likelyAuthentic = "likely_authentic"
    case likelySynthetic = "likely_synthetic"
    case inconclusive = "inconclusive"

    var label: String {
        switch self {
        case .likelyAuthentic: return "Likely Authentic"
        case .likelySynthetic: return "Likely AI-Generated"
        case .inconclusive: return "Inconclusive"
        }
    }
}

struct AnalysisResult: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let mediaKind: MediaKind
    let verdict: Verdict
    /// Model-reported confidence, 0...1. This is the model's own self-estimate,
    /// not a calibrated statistical confidence — display accordingly.
    let confidence: Double
    let reasoning: String
    let flaggedIndicators: [String]
    let rawModelText: String
    let createdAt: Date

    static func parse(rawText: String, mediaKind: MediaKind) -> AnalysisResult {
        if let json = JSONExtractor.extractJSONObject(from: rawText),
           let data = json.data(using: .utf8) {
            struct ModelJSON: Decodable {
                let verdict: String?
                let confidence: Double?
                let reasoning: String?
                let flagged_indicators: [String]?
            }
            if let parsed = try? JSONDecoder().decode(ModelJSON.self, from: data) {
                return AnalysisResult(
                    mediaKind: mediaKind,
                    verdict: Verdict(rawValue: parsed.verdict ?? "") ?? .inconclusive,
                    confidence: min(max(parsed.confidence ?? 0.5, 0), 1),
                    reasoning: parsed.reasoning ?? rawText,
                    flaggedIndicators: parsed.flagged_indicators ?? [],
                    rawModelText: rawText,
                    createdAt: Date()
                )
            }
        }
        // Model didn't return valid JSON (it happens) — surface raw text,
        // mark inconclusive rather than guessing a verdict.
        return AnalysisResult(
            mediaKind: mediaKind,
            verdict: .inconclusive,
            confidence: 0.5,
            reasoning: rawText,
            flaggedIndicators: [],
            rawModelText: rawText,
            createdAt: Date()
        )
    }
}

enum JSONExtractor {
    /// Models often wrap JSON in markdown fences or a sentence of preamble —
    /// pull out the first balanced-looking {...} block.
    static func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        return String(text[start...end])
    }
}
