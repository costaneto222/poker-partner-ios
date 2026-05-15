import Foundation
import CoreGraphics

/// Normalized bounding box — origin top-left, values 0.0–1.0.
struct RegionBox: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var confidence: Double

    /// CGRect in top-left normalized coordinates (for SwiftUI overlay math).
    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct CalibrationProfile: Codable {
    var pot:         RegionBox?
    var call:        RegionBox?
    var playerCards: RegionBox?
    var board:       RegionBox?
    var createdAt:   Date

    var isComplete: Bool { pot != nil && playerCards != nil }

    // MARK: - Persistence

    private static let key = "calibration_profile_v1"

    static func load() -> CalibrationProfile? {
        guard
            let data    = UserDefaults.standard.data(forKey: key),
            let profile = try? JSONDecoder().decode(CalibrationProfile.self, from: data)
        else { return nil }
        return profile
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: CalibrationProfile.key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
