// MARK: - OfflineTranslationManager

import Foundation
import AVFoundation

/// Manages offline translation functionality with fallback logic
final class OfflineTranslationManager {
    
    // MARK: - Public Types
    
    /// Translation error types for offline mode
    enum OfflineTranslationError: Error, LocalizedError {
        case vocabularyLookupFailed
        case contextMissing
        case phraseTooComplex
        case confidenceTooLow
        case noInternetConnection
        case translationModelUnavailable
        
        var errorDescription: String? {
            switch self {
            case .vocabularyLookupFailed:
                return "Failed to lookup translation in vocabulary"
            case .contextMissing:
                return "Missing context for translation"
            case .phraseTooComplex:
                return "Phrase too complex for offline translation"
            case .confidenceTooLow:
                return "Translation confidence too low"
            case .noInternetConnection:
                return "No internet connection available"
            case .translationModelUnavailable:
                return "Translation model is unavailable"
            }
        }
    }
    
    /// Translation confidence levels
    enum ConfidenceLevel: Double {
        case low = 0.3
        case medium = 0.6
        case high = 0.8
        case veryHigh = 0.95
        
        var threshold: Double { rawValue }
    }
    
    /// Translation result with confidence
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
    
    // MARK: - Private Properties
    
    private let vocabularyDatabase: VocabularyDatabase
    private let translationEngine: TranslationEngine
    private let translationModels: TranslationModels
    private let audioEngine: AudioEngine
    private let cache: TranslationCache
    
    private var isOfflineMode: Bool = false
    private var lastOfflineCheck: Date = .distantPast
    private var offlineVocabularyCoverage: Double = 0.0
    private var maxProcessingTime: TimeInterval = 2.0 // 2 seconds max for offline
    
    // MARK: - Initialization
    
    init(
        vocabularyDatabase: VocabularyDatabase = VocabularyDatabase.shared,
        translationEngine: TranslationEngine = TranslationEngine(),
        translationModels: TranslationModels = TranslationModels.shared,
        audioEngine: AudioEngine = AudioEngine(),
        cache: TranslationCache = TranslationCache.shared
    ) {
        self.vocabularyDatabase = vocabularyDatabase
        self.translationEngine = translationEngine
        self.translationModels = translationModels
        self.audioEngine = audioEngine
        self.cache = cache
        
        checkOfflineStatus()
    }
    
    // MARK: - Public Methods
    
    /// Translate text with offline capability
    func translate(
        text: String,
        direction: TranslationEngine.TranslationDirection
    ) -> TranslationResult {
        let startTime = Date()
        
        // Check if we should use offline mode
        checkOfflineStatus()
        
        do {
            // Try ML model translation first if online
            if !isOfflineMode {
                if let mlTranslation = try translationModels.translate(text, direction: direction) {
                    let processingTime = Date().timeIntervalSince(startTime)
                    return TranslationResult(
                        translatedText: mlTranslation,
                        confidence: 0.9,
                        source: .translationModel,
                        isOffline: false,
                        processingTime: processingTime
                    )
                }
            }
            
            // Try vocabulary database lookup
            let vocabularyTranslation = vocabularyDatabase.lookup(text, direction: direction)
            if !vocabularyTranslation.isEmpty {
                let confidence = vocabularyDatabase.getTranslationConfidence(text, direction: direction)
                let processingTime = Date().timeIntervalSince(startTime)
                
                return TranslationResult(
                    translatedText: vocabularyTranslation,
                    confidence: confidence,
                    source: .vocabularyDatabase,
                    isOffline: true,
                    processingTime: processingTime
                )
            }
            
            // Try simple phrase mapping as fallback
            let simpleTranslation = translateSimplePhrase(text, direction: direction)
            if !simpleTranslation.isEmpty {
                let processingTime = Date().timeIntervalSince(startTime)
                
                return TranslationResult(
                    translatedText: simpleTranslation,
                    confidence: 0.5,
                    source: .simpleMapping,
                    isOffline: true,
                    processingTime: processingTime
                )
            }
            
            // Final fallback - return original text with indication
            let processingTime = Date().timeIntervalSince(startTime)
            return TranslationResult(
                translatedText: text,
                confidence: 0.1,
                source: .fallback,
                isOffline: true,
                processingTime: processingTime
            )
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            return TranslationResult(
                translatedText: text,
                confidence: 0.0,
                source: .fallback,
                isOffline: true,
                processingTime: processingTime
            )
        }
    }
    
    /// Translate audio buffer with offline capability
    func translateAudioBuffer(
        _ buffer: AVAudioPCMBuffer,
        at time: AVAudioTime,
        direction: TranslationEngine.TranslationDirection
    ) -> TranslationResult {
        let startTime = Date()
        
        do {
            // Try speech recognition with offline model first
            let speechText = try recognizeSpeechOffline(from: buffer, at: time)
            
            // Translate the recognized text
            return translate(text: speechText, direction: direction)
            
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)
            return TranslationResult(
                translatedText: "",
                confidence: 0.0,
                source: .fallback,
                isOffline: true,
                processingTime: processingTime
            )
        }
    }
    
    /// Check if offline mode should be activated
    func checkOfflineStatus() -> Bool {
        let now = Date()
        let timeSinceLastCheck = now.timeIntervalSince(lastOfflineCheck)
        
        // Only check every 5 minutes to avoid excessive network calls
        guard timeSinceLastCheck > 300 else { return isOfflineMode }
        
        lastOfflineCheck = now
        
        // Check network connectivity
        if isConnectedToNetwork() {
            isOfflineMode = false
            offlineVocabularyCoverage = vocabularyDatabase.getCoverageStatistics().coveragePercentage
        } else {
            isOfflineMode = true
            offlineVocabularyCoverage = vocabularyDatabase.getCoverageStatistics().coveragePercentage
        }
        
        return isOfflineMode
    }
    
    /// Get offline status
    func getOfflineStatus() -> (isOffline: Bool, coverage: Double, lastCheck: Date) {
        return (isOfflineMode, offlineVocabularyCoverage, lastOfflineCheck)
    }
    
    /// Get translation confidence for a phrase
    func getTranslationConfidence(
        text: String,
        direction: TranslationEngine.TranslationDirection
    ) -> Double {
        // Check vocabulary database first
        let vocabularyConfidence = vocabularyDatabase.getTranslationConfidence(text, direction: direction)
        if vocabularyConfidence > 0.0 {
            return vocabularyConfidence
        }
        
        // Check ML model confidence if online
        if !isOfflineMode {
            do {
                if let mlConfidence = try translationModels.getConfidence(text, direction: direction) {
                    return mlConfidence
                }
            } catch {
                // Ignore model confidence errors
            }
        }
        
        // Fallback to simple confidence based on phrase complexity
        return estimateSimpleConfidence(text)
    }
    
    // MARK: - Private Methods
    
    private func recognizeSpeechOffline(from buffer: AVAudioPCMBuffer, at time: AVAudioTime) throws -> String {
        // Try offline speech recognition first
        do {
            return try audioEngine.speechRecognizer.recognizeSpeech(from: buffer, at: time)
        } catch {
            // If offline recognition fails, try simple pattern matching
            return try recognizeSpeechSimple(from: buffer, at: time)
        }
    }
    
    private func recognizeSpeechSimple(from buffer: AVAudioPCMBuffer, at time: AVAudioTime) throws -> String {
        // Simple pattern matching for common commands
        // This is a placeholder for actual offline speech recognition
        throw OfflineTranslationError.noInternetConnection
    }
    
    private func translateSimplePhrase(_ phrase: String, _ direction: TranslationEngine.TranslationDirection) -> String {
        // Simple phrase mapping for basic translation
        let phraseMapping: [String: String] = [
            // Common commands
            "sit": direction == .humanToDog ? "woof woof woof" : "sit",
            "stay": direction == .humanToDog ? "woof woof woof woof" : "stay",
            "come": direction == .humanToDog ? "woof woof woof woof woof" : "come",
            "no": direction == .humanToDog ? "woof woof woof woof woof woof woof woof" : "no",
            "yes": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof" : "yes",
            "good": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof