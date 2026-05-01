import Foundation
import WatchKit

/// Manages Watch face customization and quick action shortcuts
final class WatchFaceShortcutManager {
    static let shared = WatchFaceShortcutManager()

    private init() {}

    /// Registers the quick translate shortcut for Watch face
    func registerQuickTranslateShortcut() {
        // In watchOS, shortcuts are typically handled via the Info.plist
        // and CLKShortcutCommand in the extension delegate
        UserDefaults.standard.set(true, forKey: "quickTranslateEnabled")
    }

    /// Handles a shortcut command from the Watch face
    func handleQuickTranslate() -> String {
        let result = WatchTranslationService.shared.translate(
            input: "hello",
            direction: .humanToDog
        )
        HapticManager.shared.playForTranslation(result.translatedText)
        VoiceFeedbackManager.shared.speak(result.translatedText)

        let translation = WatchTranslation(
            input: "hello",
            translated: result.translatedText,
            direction: WatchTranslationDirection.humanToDog.rawValue
        )
        WatchTranslationStore.shared.save(translation)
        return result.translatedText
    }

    /// Creates a shortcut reply for Siri/shortcut integration
    func createShortcutReply() -> [String: Any] {
        let lastTranslation = WatchTranslationStore.shared.lastTranslation()
        return [
            "translation": lastTranslation?.translated ?? "Woof woof!",
            "timestamp": lastTranslation?.timestamp ?? Date()
        ]
    }
}
