import Foundation
import os.log

enum TranslationDirection: String, Codable {
    case humanToDog
    case dogToHuman
}

protocol AITranslationServiceProtocol {
    func translate(input: String, direction: TranslationDirection) async throws -> AITranslationResult
    var isModelAvailable: Bool { get }
    func loadModel() async throws
    var modelVersion: String { get }
    func fallbackTranslate(input: String, direction: TranslationDirection) -> String
    // Streaming support
    func translateStream(input: String, direction: TranslationDirection) -> AsyncThrowingStream<AITranslationResult, Error>
}

struct AITranslationResult {
    let translatedText: String
    let qualityScore: TranslationQualityScore
    let inferenceTime: TimeInterval
    let modelVersion: String

    var isConfident: Bool { qualityScore.confidence >= 0.5 }
}

struct TranslationQualityScore {
    let confidence: Double
    var qualityTier: QualityTier {
        switch confidence {
        case 0.8...: return .high
        case 0.6..<0.8: return .medium
        case 0.4..<0.6: return .low
        default: return .veryLow
        }
    }

    enum QualityTier: String {
        case high = "High", medium = "Medium", low = "Low", veryLow = "Very Low"
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

enum AITranslationError: Error, LocalizedError {
    case modelNotLoaded
    case modelLoadFailed(String)
    case translationFailed(String)
    case invalidInput
    case inferenceTimeout
    case modelUnavailable
    case retryExhausted(lastError: Error)
    case circuitOpen

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "AI model not loaded"
        case .modelLoadFailed(let reason): return "Failed to load AI model: \(reason)"
        case .translationFailed(let reason): return "AI translation failed: \(reason)"
        case .invalidInput: return "Invalid input for AI translation"
        case .inferenceTimeout: return "AI translation timed out"
        case .modelUnavailable: return "AI model is not available"
        case .retryExhausted(let lastError): return "AI translation failed after retries: \(lastError.localizedDescription)"
        case .circuitOpen: return "AI translation circuit breaker is open"
        }
    }
}

/// On-device AI translation service implementation
final class AITranslationService: AITranslationServiceProtocol {

    static let shared = AITranslationService()

    private(set) var isModelLoaded = false
    private let modelLock = NSLock()
    let modelVersion = "1.0.0"
    private let translationEngine = TranslationEngine()

    // Resilience
    private let circuitBreaker = CircuitBreaker(failureThreshold: 5, resetTimeout: 30)
    private let errorHandler = AITranslationErrorHandler()

    private init() {}

    func loadModel() async throws {
        modelLock.lock()
        defer { modelLock.unlock() }
        guard !isModelLoaded else { return }
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate model loading
        isModelLoaded = true
    }

    func translate(input: String, direction: TranslationDirection) async throws -> AITranslationResult {
        guard isModelLoaded else { throw AITranslationError.modelNotLoaded }
        guard !input.isEmpty else { throw AITranslationError.invalidInput }

        let context = TranslationContext(input: input, direction: direction, mode: .async)

        guard circuitBreaker.currentState != .open else {
            let action = errorHandler.handleError(AITranslationError.circuitOpen, context: context)
            if case .fallbackToRuleBased = action {
                return fallbackResult(for: input, direction: direction)
            }
            throw AITranslationError.circuitOpen
        }

        // Retry with exponential backoff
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                let result = try await withTimeout(seconds: 5) {
                    try await self.performTranslation(input: input, direction: direction)
                }
                circuitBreaker.onSuccess()
                return result
            } catch {
                lastError = error
                let action = errorHandler.handleError(error, context: context)
                if case .showErrorToUser = action {
                    circuitBreaker.onFailure()
                    throw error
                }
                if attempt < 2 {
                    try await Task.sleep(nanoseconds: UInt64(250 * (1 << attempt) * 1_000_000))
                }
            }
        }

        circuitBreaker.onFailure()
        os_log("Retry exhausted, using fallback: %{public}@",
               log: OSLog.default, type: .info,
               lastError?.localizedDescription ?? "unknown")
        return fallbackResult(for: input, direction: direction)
    }

    func unloadModel() {
        modelLock.lock()
        defer { modelLock.unlock() }
        isModelLoaded = false
    }

    var isModelAvailable: Bool { isModelLoaded }

    func fallbackTranslate(input: String, direction: TranslationDirection) -> String {
        switch direction {
        case .humanToDog:
            return (try? translationEngine.translateHumanToDog(speechText: input)) ?? "Translation not available"
        case .dogToHuman:
            return (try? translationEngine.translateDogToHuman(dogVocalization: input)) ?? "Translation not available"
        }
    }

    // MARK: - Streaming Translation

    func translateStream(input: String, direction: TranslationDirection) -> AsyncThrowingStream<AITranslationResult, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard self.isModelLoaded else {
                        continuation.finish(throwing: AITranslationError.modelNotLoaded)
                        return
                    }
                    guard !input.isEmpty else {
                        continuation.finish(throwing: AITranslationError.invalidInput)
                        return
                    }

                    // Emit partial result with low confidence first
                    let partialResult1 = AITranslationResult(
                        translatedText: "Translating...",
                        qualityScore: TranslationQualityScore(confidence: 0.1),
                        inferenceTime: 0,
                        modelVersion: self.modelVersion
                    )
                    continuation.yield(partialResult1)

                    // Simulate streaming chunks
                    try await Task.sleep(nanoseconds: 100_000_000)

                    let normalized = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let enhanced = Self.enhancedTranslations[direction]?[normalized]

                    let (translation, confidence): (String, Double)
                    if let found = enhanced {
                        translation = found.text
                        confidence = found.confidence
                    } else {
                        translation = self.fallbackTranslate(input: input, direction: direction)
                        confidence = 0.55
                    }

                    // Emit intermediate result
                    let partialResult2 = AITranslationResult(
                        translatedText: String(translation.prefix(translation.count / 2)),
                        qualityScore: TranslationQualityScore(confidence: confidence * 0.5),
                        inferenceTime: 0.05,
                        modelVersion: self.modelVersion
                    )
                    continuation.yield(partialResult2)

                    try await Task.sleep(nanoseconds: 100_000_000)

                    // Emit final result
                    let qualityScore = TranslationQualityScore(confidence: confidence)
                    let finalResult = AITranslationResult(
                        translatedText: translation,
                        qualityScore: qualityScore,
                        inferenceTime: 0.2,
                        modelVersion: self.modelVersion
                    )
                    continuation.yield(finalResult)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func performTranslation(input: String, direction: TranslationDirection) async throws -> AITranslationResult {
        let startTime = Date()
        try await Task.sleep(nanoseconds: 100_000_000) // Simulate inference

        let normalized = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let enhanced = Self.enhancedTranslations[direction]?[normalized]

        let (translation, confidence): (String, Double)
        if let found = enhanced {
            translation = found.text
            confidence = found.confidence
        } else {
            translation = fallbackTranslate(input: input, direction: direction)
            confidence = 0.55
        }

        let qualityScore = TranslationQualityScore(confidence: confidence)
        let inferenceTime = Date().timeIntervalSince(startTime)

        // Persist metadata
        Task {
            try? PersistenceController.shared.saveTranslation(
                original: input,
                translated: translation,
                mode: "ai",
                qualityScore: confidence,
                modelVersion: modelVersion,
                inferenceTime: inferenceTime,
                timestamp: Date()
            )
        }

        return AITranslationResult(
            translatedText: translation,
            qualityScore: qualityScore,
            inferenceTime: inferenceTime,
            modelVersion: modelVersion
        )
    }

    private func fallbackResult(for input: String, direction: TranslationDirection) -> AITranslationResult {
        AITranslationResult(
            translatedText: fallbackTranslate(input: input, direction: direction),
            qualityScore: TranslationQualityScore(confidence: 0.3),
            inferenceTime: 0,
            modelVersion: modelVersion
        )
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AITranslationError.inferenceTimeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    static let enhancedTranslations: [TranslationDirection: [String: (text: String, confidence: Double)]] = [
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
