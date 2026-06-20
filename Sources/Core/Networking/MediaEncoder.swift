import Foundation
import AVFoundation
import UIKit

enum MediaEncoder {
    static func dataURI(data: Data, mimeType: String) -> String {
        "data:\(mimeType);base64,\(data.base64EncodedString())"
    }

    static func imageDataURI(_ image: UIImage, quality: CGFloat = 0.85) -> String? {
        guard let jpeg = image.jpegData(compressionQuality: quality) else { return nil }
        return dataURI(data: jpeg, mimeType: "image/jpeg")
    }

    static func videoDataURI(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return dataURI(data: data, mimeType: mimeType(for: url))
    }

    static func audioDataURI(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return dataURI(data: data, mimeType: mimeType(for: url))
    }

    /// Alternative to sending a full video: extract evenly spaced frames and
    /// analyze them as a still-image sequence. Useful if your endpoint can't
    /// handle large base64 video payloads, or for cheaper/faster requests.
    static func extractFrames(from url: URL, maxFrames: Int = 6) async throws -> [UIImage] {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let totalSeconds = CMTimeGetSeconds(duration)
        guard totalSeconds > 0 else { return [] }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let count = max(1, min(maxFrames, Int(totalSeconds) + 1))
        let times: [CMTime] = (0..<count).map { i in
            let t = totalSeconds * Double(i) / Double(max(count - 1, 1))
            return CMTime(seconds: t, preferredTimescale: 600)
        }

        var images: [UIImage] = []
        for time in times {
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                images.append(UIImage(cgImage: cgImage))
            }
        }
        return images
    }

    private static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        case "m4a": return "audio/mp4"
        case "wav": return "audio/wav"
        case "mp3": return "audio/mpeg"
        default: return "application/octet-stream"
        }
    }
}
