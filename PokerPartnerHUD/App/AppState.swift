import Foundation
import Combine

enum AppScreen { case setup, calibrating, running }

final class AppState: ObservableObject {
    @Published var screen: AppScreen = .setup
    @Published var stack: Double = 100.0

    func startCalibration() { screen = .calibrating }
    func startRunning()     { screen = .running      }
    func backToSetup()      { screen = .setup         }
}
