import Foundation

/// Manages translation models and ML processing
final class TranslationModels {

    static let shared = TranslationModels()
    private var model: TranslateModel? = nil

    private init() {
        model = TranslateModel()
    }

    func translate(_ text: String, direction: TranslationDirection) throws -> String? {
        guard let model = model else { throw TranslationEngine.TranslationError.modelUnavailable }
        return try model.translate(text, direction: direction)
    }

    func translateWithFallback(_ text: String, direction: TranslationDirection) throws -> String {
        guard let result = try translate(text, direction: direction) else {
            throw TranslationEngine.TranslationError.translationFailed
        }
        return result
    }

    func isModelAvailable() -> Bool {
        model != nil
    }
}

// MARK: - TranslateModel

final class TranslateModel {

    func translate(_ text: String, direction: TranslationDirection) throws -> String? {
        let phraseMapping: [String: String] = [
            "sit": direction == .humanToDog ? "woof woof woof" : "sit",
            "stay": direction == .humanToDog ? "woof woof woof woof" : "stay",
            "come": direction == .humanToDog ? "woof woof woof woof woof" : "come",
            "hello": direction == .humanToDog ? "woof woof" : "hello",
        ]
        guard let translated = phraseMapping[text.lowercased()] else {
            return nil
        }
        return translated
    }
}
