// MARK: - TranslationEngine

import Foundation
import AVFoundation

/// Core translation engine for real-time translation between human speech and dog vocalizations
final class TranslationEngine {
    
    // MARK: - Public Types
    
    /// Translation direction
    enum TranslationDirection {
        case humanToDog
        case dogToHuman
    }
    
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
    
    private var translationRequests: Int = 0
    private var successfulTranslations: Int = 0
    private var failedTranslations: Int = 0
    private var lastTranslationError: TranslationError?
    
    // MARK: - Initialization
    
    init(
        vocabularyDatabase: VocabularyDatabase = VocabularyDatabase.shared,
        translationModels: TranslationModels = TranslationModels.shared,
        audioEngine: AudioEngine = AudioEngine()
    ) {
        self.vocabularyDatabase = vocabularyDatabase
        self.translationModels = translationModels
        self.audioEngine = audioEngine
        self.speechRecognizer = audioEngine.speechRecognizer
        self.audioPlayback = audioEngine.audioPlayback
        
        setupAudioEngine()
    }
    
    // MARK: - Public Methods
    
    /// Translate human speech to dog vocalizations
    func translateHumanToDog(speechText: String) throws -> String {
        translationRequests += 1
        
        guard !speechText.isEmpty else {
            throw TranslationError.invalidInput
        }
        
        do {
            // Try ML model translation first
            if let mlTranslation = try translationModels.translateHumanToDog(speechText) {
                successfulTranslations += 1
                return mlTranslation
            }
            
            // Fallback to vocabulary lookup
            let vocabularyTranslation = vocabularyDatabase.lookupHumanToDog(speechText)
            if !vocabularyTranslation.isEmpty {
                successfulTranslations += 1
                return vocabularyTranslation
            }
            
            // If all else fails, use simple phrase mapping
            let simpleTranslation = translateSimplePhrase(speechText, direction: .humanToDog)
            if !simpleTranslation.isEmpty {
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
        
        do {
            // Try ML model translation first
            if let mlTranslation = try translationModels.translateDogToHuman(dogVocalization) {
                successfulTranslations += 1
                return mlTranslation
            }
            
            // Fallback to vocabulary lookup
            let vocabularyTranslation = vocabularyDatabase.lookupDogToHuman(dogVocalization)
            if !vocabularyTranslation.isEmpty {
                successfulTranslations += 1
                return vocabularyTranslation
            }
            
            // If all else fails, use simple phrase mapping
            let simpleTranslation = translateSimplePhrase(dogVocalization, direction: .dogToHuman)
            if !simpleTranslation.isEmpty {
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
    
    private func translateSimplePhrase(_ phrase: String, direction: TranslationDirection) -> String {
        // Simple phrase mapping for basic translation
        let phraseMapping: [String: String] = [
            "hello": direction == .humanToDog ? "woof woof" : "hello",
            "sit": direction == .humanToDog ? "woof woof woof" : "sit",
            "stay": direction == .humanToDog ? "woof woof woof woof" : "stay",
            "come": direction == .humanToDog ? "woof woof woof woof woof" : "come",
            "good boy": direction == .humanToDog ? "woof woof woof woof woof woof" : "good boy",
            "good girl": direction == .humanToDog ? "woof woof woof woof woof woof woof" : "good girl",
            "no": direction == .humanToDog ? "woof woof woof woof woof woof woof woof" : "no",
            "yes": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof" : "yes",
            "walk": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof" : "walk",
            "food": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof" : "food",
            "play": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof" : "play",
            "ball": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof" : "ball",
            "treat": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof" : "treat",
            "outside": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof" : "outside",
            "inside": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof" : "inside",
            "bed": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof" : "bed",
            "toy": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof" : "toy",
            "water": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof" : "water",
            "bath": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof" : "bath",
            "vet": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof" : "vet",
            "park": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof" : "park"
        ]
        
        return phraseMapping[phrase.lowercased()] ?? ""
    }
}

// MARK: - TranslationEngineDelegate

protocol TranslationEngineDelegate: AnyObject {
    func translationEngine(_ engine: TranslationEngine, didTranslate text: String, direction: TranslationEngine.TranslationDirection)
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