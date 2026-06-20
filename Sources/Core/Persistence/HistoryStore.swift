import Foundation
import Combine

/// Simple on-device JSON file store for past analyses. Nothing is sent
/// anywhere except to the configured inference endpoint at analysis time.
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [AnalysisResult] = []

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("proofy_history.json")
        load()
    }

    func add(_ result: AnalysisResult) {
        items.insert(result, at: 0)
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        items = (try? JSONDecoder().decode([AnalysisResult].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
