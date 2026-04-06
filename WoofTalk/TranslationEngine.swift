// MARK: - TranslationEngine

import Foundation
import AVFoundation

/// Core translation engine for real-time translation between human speech and dog vocalizations
final class TranslationEngine {
    
    // MARK: - Public Types

    /// Translation error types
    enum TranslationError: Error, LocalizedError {
        case invalidInput
        case modelUnavailable
        case translationFailed
        case vocabularyLookupFailed
        case audioProcessingFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidInput:
                return "Invalid input for translation"
            case .modelUnavailable:
                return "Translation model is unavailable"
            case .translationFailed:
                return "Translation failed"
            case .vocabularyLookupFailed:
                return "Failed to lookup vocabulary"
            case .audioProcessingFailed:
                return "Audio processing failed"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let vocabularyDatabase: VocabularyDatabase
    private let translationModels: TranslationModels
    private let audioEngine: AudioEngine
    private let speechRecognizer: SpeechRecognition
    private let audioPlayback: AudioPlayback
    private let cache: TranslationCache

    private var translationRequests: Int = 0
    private var successfulTranslations: Int = 0
    private var failedTranslations: Int = 0
    private var lastTranslationError: TranslationError?

    // MARK: - Initialization

    init(
        vocabularyDatabase: VocabularyDatabase = VocabularyDatabase.shared,
        translationModels: TranslationModels = TranslationModels.shared,
        audioEngine: AudioEngine = AudioEngine(),
        cache: TranslationCache = TranslationCache.shared
    ) {
        self.vocabularyDatabase = vocabularyDatabase
        self.translationModels = translationModels
        self.audioEngine = audioEngine
        self.speechRecognizer = audioEngine.speechRecognizer
        self.audioPlayback = audioEngine.audioPlayback
        self.cache = cache

        setupAudioEngine()
    }
    
    // MARK: - Public Methods
    
    /// Translate human speech to dog vocalizations
    func translateHumanToDog(speechText: String) throws -> String {
        translationRequests += 1

        guard !speechText.isEmpty else {
            throw TranslationError.invalidInput
        }

        // Check cache first
        if let cached = cache.getCachedTranslation(text: speechText, direction: .humanToDog) {
            successfulTranslations += 1
            return cached.translatedText
        }

        do {
            // Try ML model translation first
            if let mlTranslation = try translationModels.translateHumanToDog(speechText) {
                cache.cacheTranslation(text: speechText, translatedText: mlTranslation, direction: .humanToDog, confidence: 1.0)
                successfulTranslations += 1
                return mlTranslation
            }

            // Fallback to vocabulary lookup
            let vocabularyTranslation = vocabularyDatabase.lookupHumanToDog(speechText)
            if !vocabularyTranslation.isEmpty {
                cache.cacheTranslation(text: speechText, translatedText: vocabularyTranslation, direction: .humanToDog, confidence: 0.8)
                successfulTranslations += 1
                return vocabularyTranslation
            }

            // If all else fails, use simple phrase mapping
            let simpleTranslation = translateSimplePhrase(speechText, direction: .humanToDog)
            if !simpleTranslation.isEmpty {
                cache.cacheTranslation(text: speechText, translatedText: simpleTranslation, direction: .humanToDog, confidence: 0.5)
                successfulTranslations += 1
                return simpleTranslation
            }

            throw TranslationError.translationFailed

        } catch {
            failedTranslations += 1
            lastTranslationError = error as? TranslationError ?? .translationFailed
            throw error
        }
    }

    /// Translate dog vocalizations to human speech
    func translateDogToHuman(dogVocalization: String) throws -> String {
        translationRequests += 1

        guard !dogVocalization.isEmpty else {
            throw TranslationError.invalidInput
        }

        // Check cache first
        if let cached = cache.getCachedTranslation(text: dogVocalization, direction: .dogToHuman) {
            successfulTranslations += 1
            return cached.translatedText
        }

        do {
            // Try ML model translation first
            if let mlTranslation = try translationModels.translateDogToHuman(dogVocalization) {
                cache.cacheTranslation(text: dogVocalization, translatedText: mlTranslation, direction: .dogToHuman, confidence: 1.0)
                successfulTranslations += 1
                return mlTranslation
            }

            // Fallback to vocabulary lookup
            let vocabularyTranslation = vocabularyDatabase.lookupDogToHuman(dogVocalization)
            if !vocabularyTranslation.isEmpty {
                cache.cacheTranslation(text: dogVocalization, translatedText: vocabularyTranslation, direction: .dogToHuman, confidence: 0.8)
                successfulTranslations += 1
                return vocabularyTranslation
            }

            // If all else fails, use simple phrase mapping
            let simpleTranslation = translateSimplePhrase(dogVocalization, direction: .dogToHuman)
            if !simpleTranslation.isEmpty {
                cache.cacheTranslation(text: dogVocalization, translatedText: simpleTranslation, direction: .dogToHuman, confidence: 0.5)
                successfulTranslations += 1
                return simpleTranslation
            }

            throw TranslationError.translationFailed

        } catch {
            failedTranslations += 1
            lastTranslationError = error as? TranslationError ?? .translationFailed
            throw error
        }
    }
    
    /// Translate audio buffer containing human speech to dog vocalizations
    func translateAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) throws -> String {
        do {
            let speechText = try speechRecognizer.recognizeSpeech(from: buffer, at: time)
            return try translateHumanToDog(speechText: speechText)
        } catch {
            throw TranslationError.audioProcessingFailed
        }
    }
    
    /// Get translation engine status
    func getStatus() -> TranslationEngineStatus {
        return TranslationEngineStatus(
            requests: translationRequests,
            successfulTranslations: successfulTranslations,
            failedTranslations: failedTranslations,
            lastError: lastTranslationError,
            vocabularyCoverage: vocabularyDatabase.getCoverageStatistics()
        )
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine() {
        audioEngine.delegate = self
    }
    
    private static let humanToDogPhrases: [String: String] = [
        "hello": "woof woof",
        "sit": "woof woof woof",
        "stay": "woof woof woof woof",
        "come": "woof woof woof woof woof",
        "good boy": "woof woof woof woof woof woof",
        "good girl": "woof woof woof woof woof woof woof",
        "no": "woof woof woof woof woof woof woof woof",
        "yes": "woof woof woof woof woof woof woof woof woof",
        "walk": "woof woof woof woof woof woof woof woof woof woof",
        "food": "woof woof woof woof woof woof woof woof woof woof woof",
        "play": "woof woof woof woof woof woof woof woof woof woof woof woof",
        "ball": "woof woof woof woof woof woof woof woof woof woof woof woof woof",
        "treat": "woof woof woof woof woof woof woof woof woof woof woof woof woof woof",
        "outside": "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof",
        "inside": "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof",
        "bed": "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof",
        "toy": "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof",
        "water": "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof",
        "bath": "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof",
        "vet": "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof",
        "park": "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof",
    ]

    private static let dogToHumanPhrases: [String: String] = [
        "hello": "hello",
        "sit": "sit",
        "stay": "stay",
        "come": "come",
        "good boy": "good boy",
        "good girl": "good girl",
        "no": "no",
        "yes": "yes",
        "walk": "walk",
        "food": "food",
        "play": "play",
        "ball": "ball",
        "treat": "treat",
        "outside": "outside",
        "inside": "inside",
        "bed": "bed",
        "toy": "toy",
        "water": "water",
        "bath": "bath",
        "vet": "vet",
        "park": "park",
    ]

    private func translateSimplePhrase(_ phrase: String, direction: TranslationDirection) -> String {
        let mapping = direction == .humanToDog
            ? Self.humanToDogPhrases
            : Self.dogToHumanPhrases
        return mapping[phrase.lowercased()] ?? ""
    }
}

// MARK: - TranslationEngineDelegate

protocol TranslationEngineDelegate: AnyObject {
    func translationEngine(_ engine: TranslationEngine, didTranslate text: String, direction: TranslationDirection)
    func translationEngine(_ engine: TranslationEngine, didFailWithError error: Error)
    func translationEngineDidStart(_ engine: TranslationEngine)
    func translationEngineDidStop(_ engine: TranslationEngine)
}

// MARK: - TranslationEngineStatus

struct TranslationEngineStatus: CustomStringConvertible {
    let requests: Int
    let successfulTranslations: Int
    let failedTranslations: Int
    let lastError: TranslationEngine.TranslationError?
    let vocabularyCoverage: VocabularyCoverage
    
    var description: String {
        return "TranslationEngineStatus(requests: \(requests), success: \(successfulTranslations), failed: \(failedTranslations), coverage: \(vocabularyCoverage))"
    }
}

// MARK: - VocabularyCoverage

struct VocabularyCoverage: CustomStringConvertible {
    let humanToDogPhrases: Int
    let dogToHumanPhrases: Int
    let totalPhrases: Int
    let coveragePercentage: Double
    
    var description: String {
        return "VocabularyCoverage(humanToDog: \(humanToDogPhrases), dogToHuman: \(dogToHumanPhrases), total: \(totalPhrases), coverage: \(String(format: "%.1f", coveragePercentage))%)")
    }
}

// MARK: - AudioEngineDelegate Extension

extension TranslationEngine: AudioEngineDelegate {
    func audioEngine(_ engine: AudioEngine, didRecognizeSpeech text: String) {
        // Forward speech recognition results to translation engine
        do {
            let translation = try translateHumanToDog(speechText: text)
            // Notify delegate if needed
        } catch {
            // Handle translation failure
        }
    }
    
    func audioEngine(_ engine: AudioEngine, didFailWithError error: Error) {
        // Forward audio engine errors
    }
    
    func audioEngineDidStart(_ engine: AudioEngine) {
        // Engine started
    }
    
    func audioEngineDidStop(_ engine: AudioEngine) {
        // Engine stopped
    }
}