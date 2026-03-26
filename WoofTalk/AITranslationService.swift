// MARK: - AITranslationService

import Foundation
import CoreML
import CoreData

/// Translation direction enum
enum TranslationDirection {
    case humanToDog
    case dogToHuman
}

/// Protocol defining AI translation capabilities
protocol AITranslationServiceProtocol {
    func translate(input: String, direction: TranslationDirection) async throws -> AITranslationResult
    var isModelAvailable: Bool { get }
    func loadModel() async throws
    var modelVersion: String { get }
    func fallbackTranslate(input: String, direction: TranslationDirection) -> String
}

/// Result of AI translation with quality metrics
struct AITranslationResult {
    let translatedText: String
    let qualityScore: TranslationQualityScore
    let inferenceTime: TimeInterval
    let modelVersion: String
    
    /// Whether the AI translation is confident enough to use
    var isConfident: Bool {
        return qualityScore.confidence >= 0.5
    }
}

/// Quality score for translation
struct TranslationQualityScore {
    /// Confidence level from 0.0 to 1.0
    let confidence: Double
    
    /// Estimated accuracy based on model metrics
    let estimatedAccuracy: Double
    
    /// Quality tier based on confidence
    var qualityTier: QualityTier {
        if confidence >= 0.8 {
            return .high
        } else if confidence >= 0.6 {
            return .medium
        } else if confidence >= 0.4 {
            return .low
        } else {
            return .veryLow
        }
    }
    
    enum QualityTier: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"
        case veryLow = "Very Low"
        
        var color: String {
            switch self {
            case .high: return "green"
            case .medium: return "yellow"
            case .low: return "orange"
            case .veryLow: return "red"
            }
        }
    }
}

/// Error types for AI translation
enum AITranslationError: Error, LocalizedError {
    case modelNotLoaded
    case modelLoadFailed(String)
    case translationFailed(String)
    case invalidInput
    case inferenceTimeout
    case modelUnavailable
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "AI model not loaded"
        case .modelLoadFailed(let reason):
            return "Failed to load AI model: \(reason)"
        case .translationFailed(let reason):
            return "AI translation failed: \(reason)"
        case .invalidInput:
            return "Invalid input for AI translation"
        case .inferenceTimeout:
            return "AI translation timed out"
        case .modelUnavailable:
            return "AI model is not available"
        }
    }
}

/// On-device AI translation service implementation
final class AITranslationService: AITranslationServiceProtocol {
    
    // MARK: - Singleton
    
    static let shared = AITranslationService()
    
    // MARK: - Properties
    
    private(set) var isModelLoaded: Bool = false
    private let modelLock = NSLock()
    
    /// Model version for tracking
    let modelVersion = "1.0.0"
    
    /// Simulated model availability (in production, check CoreML model)
    private var _modelAvailable: Bool = true
    
    var isModelAvailable: Bool {
        return isModelLoaded && _modelAvailable
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Load the AI translation model
    func loadModel() async throws {
        modelLock.lock()
        defer { modelLock.unlock() }
        
        guard !isModelLoaded else { return }
        
        // In production: Load CoreML model here
        // For now, simulate model loading
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s simulation
        
        isModelLoaded = true
    }
    
    /// Translate input using AI model
    func translate(input: String, direction: TranslationDirection) async throws -> AITranslationResult {
        guard isModelLoaded else {
            throw AITranslationError.modelNotLoaded
        }
        
        guard !input.isEmpty else {
            throw AITranslationError.invalidInput
        }
        
        let startTime = Date()
        
        // In production: Run actual ML inference
        // For now, use enhanced translation with quality scoring
        let result = try await performAITranslation(input: input, direction: direction)
        
        let inferenceTime = Date().timeIntervalSince(startTime)
        
        let aiResult = AITranslationResult(
            translatedText: result.translation,
            qualityScore: result.qualityScore,
            inferenceTime: inferenceTime,
            modelVersion: modelVersion
        )
        
        // Persist AI translation metadata to Core Data
        let modeString = (direction == .humanToDog) ? "humanToDog" : "dogToHuman"
        let quality = result.qualityScore.confidence
        let modelVer = modelVersion
        
        // Save on main thread
        await MainActor.run {
            do {
                try PersistenceController.shared.saveTranslation(
                    original: input,
                    translated: result.translation,
                    mode: "ai",
                    qualityScore: quality,
                    modelVersion: modelVer,
                    inferenceTime: inferenceTime,
                    timestamp: Date()
                )
            } catch {
                print("Failed to save translation metadata: \(error)")
            }
        }
        
        return aiResult
    }
    
    /// Unload model to free resources
    func unloadModel() {
        modelLock.lock()
        defer { modelLock.unlock() }
        
        isModelLoaded = false
    }
    
    // MARK: - Private Methods
    
    /// Perform AI translation (simulated for demo)
    private func performAITranslation(input: String, direction: TranslationDirection) async throws -> (translation: String, qualityScore: TranslationQualityScore) {
        
        // Simulate inference delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        // Enhanced translations with contextual understanding
        let enhancedTranslations = getEnhancedTranslations()
        
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find enhanced translation
        let translation: String
        let confidence: Double
        
        if let found = enhancedTranslations[direction]?[normalizedInput] {
            translation = found.text
            confidence = found.confidence
        } else {
            // Fallback to rule-based with moderate confidence
            translation = fallbackTranslation(input: input, direction: direction)
            confidence = 0.55
        }
        
        let qualityScore = TranslationQualityScore(
            confidence: confidence,
            estimatedAccuracy: confidence * 0.95
        )
        
        return (translation, qualityScore)
    }
    
    /// Get enhanced translations dictionary
    private func getEnhancedTranslations() -> [TranslationDirection: [String: (text: String, confidence: Double)]] {
        return [
            .dogToHuman: [
                "woof woof": ("Hello! I'm happy to see you!", 0.92),
                "woof woof woof": ("Let's go for a walk!", 0.88),
                "woof woof woof woof": ("I need to go outside!", 0.85),
                "whine whine": ("I'm worried or anxious", 0.78),
                "bark bark": ("Alert! Something is happening", 0.82),
                "growl": ("I'm warning you to stay back", 0.75),
                "howl": ("I'm calling for my pack / I miss you", 0.80),
                "whimper": ("I'm in pain or seeking attention", 0.72),
                "yelp": ("Ouch! That hurt!", 0.85),
                "sniff sniff": ("I'm investigating a scent", 0.70)
            ],
            .humanToDog: [
                "hello": ("Woof! Hello!", 0.90),
                "good boy": ("Tail wag! I'm a good boy!", 0.88),
                "good girl": ("Tail wag! I'm a good girl!", 0.88),
                "sit": ("I'll sit down", 0.85),
                "stay": ("I'll stay here", 0.82),
                "come": ("Coming to you!", 0.80),
                "food": ("Yum! Food time!", 0.90),
                "walk": ("Walk! Walk! Let's go!", 0.92),
                "play": ("Play time! Fetch!", 0.85),
                "ball": ("Ball! Throw the ball!", 0.88),
                "treat": ("Treat! I want a treat!", 0.90),
                "outside": ("Outside! I need to go out!", 0.85),
                "no": ("I understand, no", 0.75),
                "yes": ("Yes! I understand!", 0.75)
            ]
        ]
    }
    
    /// Fallback translation using rule-based engine
    private func fallbackTranslation(input: String, direction: TranslationDirection) -> String {
        // Use existing TranslationEngine as fallback
        let engine = TranslationEngine()
        
        do {
            if direction == .humanToDog {
                return try engine.translateHumanToDog(speechText: input)
            } else {
                return try engine.translateDogToHuman(dogVocalization: input)
            }
        } catch {
            return "Translation not available"
        }
    }
    
    /// Synchronous fallback translation for rule-based mode
    func fallbackTranslate(input: String, direction: TranslationDirection) -> String {
        let engine = TranslationEngine()
        do {
            if direction == .humanToDog {
                return try engine.translateHumanToDog(speechText: input)
            } else {
                return try engine.translateDogToHuman(dogVocalization: input)
            }
        } catch {
            return "Translation not available"
        }
    }
}