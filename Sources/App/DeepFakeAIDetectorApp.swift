import SwiftUI

@main
struct DeepFakeAIDetectorApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var historyStore = HistoryStore()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(settings)
                .environmentObject(historyStore)
                .preferredColorScheme(.dark)
                .tint(ProofyPalette.neonGreen)
        }
    }
}
