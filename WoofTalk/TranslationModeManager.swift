// MARK: - TranslationModeManager

import Foundation

/// Manages translation mode switching between modes
final class TranslationModeManager {

    enum TranslationMode: String, CaseIterable {
        case ruleBased = "Rule-Based"
        case ai = "AI"
    }

    private(set) var currentMode: TranslationMode = .ruleBased

    func setMode(_ mode: TranslationMode) { currentMode = mode }
}
