// MARK: - TranslationView Extensions

import SwiftUI

extension TranslationView {
    func addTranslation(human: String, dog: String) {
        DispatchQueue.main.async {
            // Update UI with new translation
            self.inputText = human
            self.translatedText = dog
            self.translationStatus = "Translation complete"
        }
    }
    
    func clearTranslations() {
        DispatchQueue.main.async {
            self.inputText = ""
            self.translatedText = ""
            self.translationStatus = "Ready to translate"
        }
    }
    
    func showPartialRecognition(_ text: String) {
        DispatchQueue.main.async {
            self.translationStatus = "Recognizing... \(text)"
        }
    }
    
    func updateAudioLevel(_ level: Float) {
        DispatchQueue.main.async {
            self.audioLevel = level
        }
    }
}