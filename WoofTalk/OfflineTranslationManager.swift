import Foundation

/// Manages offline translation functionality with fallback logic
final class OfflineTranslationManager {

    struct TranslationResult {
        let translatedText: String
        let confidence: Double
        let source: TranslationSource
        let isOffline: Bool
        let processingTime: TimeInterval

        enum TranslationSource {
            case vocabularyDatabase
            case translationModel
            case simpleMapping
            case fallback
        }
    }

    private let vocabularyDatabase: VocabularyDatabase
    private let translationEngine: TranslationEngine
    private let translationModels: TranslationModels
    private let cache: TranslationCache

    private var isOfflineMode = false
    private var lastOfflineCheck = Date.distantPast
    private var offlineVocabularyCoverage: Double = 0.0
    private let maxProcessingTime: TimeInterval = 2.0

    init(
        vocabularyDatabase: VocabularyDatabase = .shared,
        translationEngine: TranslationEngine = TranslationEngine(),
        translationModels: TranslationModels = .shared,
        cache: TranslationCache = .shared
    ) {
        self.vocabularyDatabase = vocabularyDatabase
        self.translationEngine = translationEngine
        self.translationModels = translationModels
        self.cache = cache
    }

    /// Translate text with offline capability
    func translate(text: String, direction: TranslationDirection) -> TranslationResult {
        let startTime = Date()
        checkOfflineStatus()

        if !isOfflineMode {
            if let mlTranslation = try? translationModels.translate(text, direction: direction) {
                let processingTime = Date().timeIntervalSince(startTime)
                return TranslationResult(translatedText: mlTranslation, confidence: 0.9, source: .translationModel, isOffline: false, processingTime: processingTime)
            }
        }

        if let vocabResult = lookupInVocabulary(text: text, direction: direction) {
            let processingTime = Date().timeIntervalSince(startTime)
            return TranslationResult(translatedText: vocabResult.0, confidence: vocabResult.1, source: .vocabularyDatabase, isOffline: isOfflineMode, processingTime: processingTime)
        }

        if let simpleMapping = applySimpleMapping(text: text, direction: direction) {
            let processingTime = Date().timeIntervalSince(startTime)
            return TranslationResult(translatedText: simpleMapping, confidence: 0.6, source: .simpleMapping, isOffline: isOfflineMode, processingTime: processingTime)
        }

        let processingTime = Date().timeIntervalSince(startTime)
        return TranslationResult(translatedText: fallbackTranslation(for: text), confidence: 0.3, source: .fallback, isOffline: isOfflineMode, processingTime: processingTime)
    }

    private func checkOfflineStatus() {
        let now = Date()
        guard now.timeIntervalSince(lastOfflineCheck) > 5.0 else { return }
        lastOfflineCheck = now
        guard let url = URL(string: "https://www.google.com") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0
        isOfflineMode = !((try? String(contentsOf: url)) != nil)
    }

    private func lookupInVocabulary(text: String, direction: TranslationDirection) -> (String, Double)? {
        return vocabularyDatabase.lookup(text: text, direction: direction)
    }

    private func applySimpleMapping(text: String, direction: TranslationDirection) -> String? {
        let lowercased = text.lowercased()
        if direction == .humanToAnimal {
            let mappings = ["hello": "woof!", "goodbye": "woof woof...", "yes": "woof!", "no": "grrr"]
            return mappings[lowercased]
        }
        return nil
    }

    private func fallbackTranslation(for text: String) -> String {
        return "Woof! (offline mode)"
    }

    func getOfflineVocabularyCoverage() -> Double {
        if Date().timeIntervalSince(lastOfflineCheck) > 60 {
            offlineVocabularyCoverage = vocabularyDatabase.getCoverage()
        }
        return offlineVocabularyCoverage
    }
}

enum TranslationDirection {
    case humanToAnimal
    case animalToHuman
}
