import Foundation

/// Core translation engine for real-time translation between human speech and dog vocalizations
final class TranslationEngine {

    enum TranslationError: Error, LocalizedError {
        case invalidInput
        case modelUnavailable
        case translationFailed

        var errorDescription: String? {
            switch self {
            case .invalidInput: return "Invalid input for translation"
            case .modelUnavailable: return "Translation model is unavailable"
            case .translationFailed: return "Translation failed"
            }
        }
    }

    private let vocabularyDatabase: VocabularyDatabase
    private let translationModels: TranslationModels
    private let cache: TranslationCache

    init(
        vocabularyDatabase: VocabularyDatabase = .shared,
        translationModels: TranslationModels = .shared,
        cache: TranslationCache = .shared
    ) {
        self.vocabularyDatabase = vocabularyDatabase
        self.translationModels = translationModels
        self.cache = cache
    }

    func translate(_ text: String, direction: TranslationDirection) throws -> String {
        guard !text.isEmpty else { throw TranslationError.invalidInput }

        if let cached = cache.getCachedTranslation(text: text, direction: direction) {
            return cached.translatedText
        }

        if let mlTranslation = try translationModels.translate(text, direction: direction) {
            cache.cacheTranslation(text: text, translatedText: mlTranslation, direction: direction, confidence: 1.0)
            saveTranslationForWidgets(humanText: text, dogTranslation: mlTranslation)
            SpotlightIndexer.shared.indexTranslation(RecentTranslation(humanText: text, dogTranslation: mlTranslation, timestamp: Date()))
            return mlTranslation
        }

        let vocabularyTranslation = direction == .humanToDog
            ? vocabularyDatabase.lookupHumanToDog(text)
            : vocabularyDatabase.lookupDogToHuman(text)
        if !vocabularyTranslation.isEmpty {
            cache.cacheTranslation(text: text, translatedText: vocabularyTranslation, direction: direction, confidence: 0.8)
            saveTranslationForWidgets(humanText: text, dogTranslation: vocabularyTranslation)
            SpotlightIndexer.shared.indexTranslation(RecentTranslation(humanText: text, dogTranslation: vocabularyTranslation, timestamp: Date()))
            return vocabularyTranslation
        }

        let simpleTranslation = translateSimplePhrase(text, direction: direction)
        if !simpleTranslation.isEmpty {
            cache.cacheTranslation(text: text, translatedText: simpleTranslation, direction: direction, confidence: 0.5)
            saveTranslationForWidgets(humanText: text, dogTranslation: simpleTranslation)
            SpotlightIndexer.shared.indexTranslation(RecentTranslation(humanText: text, dogTranslation: simpleTranslation, timestamp: Date()))
            return simpleTranslation
        }

        throw TranslationError.translationFailed
    }

    private func saveTranslationForWidgets(humanText: String, dogTranslation: String) {
        let defaults = UserDefaults(suiteName: "group.vandopha.WoofTalk") ?? UserDefaults.standard
        var translations: [RecentTranslation] = []
        if let data = defaults.data(forKey: "recentTranslations"),
           let existing = try? JSONDecoder().decode([RecentTranslation].self, from: data) {
            translations = Array(existing.prefix(9))
        }
        translations.insert(RecentTranslation(humanText: humanText, dogTranslation: dogTranslation, timestamp: Date()), at: 0)
        if let data = try? JSONEncoder().encode(Array(translations.prefix(10))) {
            defaults.set(data, forKey: "recentTranslations")
        }
    }

    private static let humanToDogPhrases: [String: String] = [
        "hello": "woof woof", "sit": "woof woof woof", "stay": "woof woof woof woof",
        "come": "woof woof woof woof woof", "good boy": "woof woof woof woof woof woof",
        "good girl": "woof woof woof woof woof woof woof"
    ]

    private static let dogToHumanPhrases: [String: String] = [
        "hello": "hello", "sit": "sit", "stay": "stay", "come": "come",
        "good boy": "good boy", "good girl": "good girl", "no": "no", "yes": "yes"
    ]

    private func translateSimplePhrase(_ phrase: String, direction: TranslationDirection) -> String {
        let mapping = direction == .humanToDog ? Self.humanToDogPhrases : Self.dogToHumanPhrases
        return mapping[phrase.lowercased()] ?? ""
    }
}
