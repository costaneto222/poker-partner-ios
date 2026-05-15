import SwiftUI

@main
struct PokerPartnerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.screen {
        case .setup:
            SetupView()
        case .calibrating:
            CalibrationView()
        case .running:
            RunningView()
        }
    }
}
