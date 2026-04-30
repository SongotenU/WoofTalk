import UIKit

/// Manages Dynamic Island integration for iPhone 14 Pro+ users
@available(iOS 16.1, *)
final class DynamicIslandManager {
    static let shared = DynamicIslandManager()

    private init() {}

    /// Check if device supports Dynamic Island
    var isSupported: Bool {
        let deviceName = UIDevice.current.name.lowercased()
        return deviceName.contains("iphone 14 pro") || deviceName.contains("iphone 15")
    }

    /// Update Dynamic Island with translation status
    func updateTranslationStatus(_ status: String, progress: Double = 0.0) {
        guard isSupported else { return }
        LiveActivityManager.shared.updateLiveActivity(
            phrase: "Active Translation",
            status: status,
            progress: progress
        )
    }

    /// Show translation completed in Dynamic Island
    func showTranslationComplete() {
        guard isSupported else { return }
        LiveActivityManager.shared.endLiveActivity()
    }

    /// Show incoming translation notification in Dynamic Island
    func showIncomingTranslation(from language: String) {
        guard isSupported else { return }
        LiveActivityManager.shared.startLiveActivity(phrase: "From \(language)")
    }
}
