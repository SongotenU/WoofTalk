// MARK: - TranslationModels

import Foundation
import CoreML
import NaturalLanguage
import os.log

/// Manages translation models and ML processing
final class TranslationModels {

    // MARK: - Public Types

    /// Model translation result
    struct ModelTranslationResult {
        let translatedText: String
        let confidence: Double
        let processingTime: TimeInterval
        let modelVersion: String
    }

    // MARK: - Private Properties

    static let shared = TranslationModels()
    private var model: TranslateModel? = nil
    private let modelQueue = DispatchQueue(label: "com.wooftalk.translation.model")
    private let modelProcessingQueue = DispatchQueue(label: "com.wooftalk.translation.model.processing", qos: .userInitiated)
    private var modelLoadAttempts: Int = 0
    private let maxModelLoadAttempts: Int = 3
    private let modelLoadTimeout: TimeInterval = 10.0

    // MARK: - Initialization

    private init() {
        loadModel()
    }

    // MARK: - Public Methods

    /// Translate text using ML model
    func translate(
        _ text: String,
        direction: TranslationDirection
    ) throws -> String? {
        guard let model = model else {
            throw TranslationError.modelUnavailable
        }

        let startTime = Date()

        do {
            let translatedText = try model.translate(text, direction: direction)
            let processingTime = Date().timeIntervalSince(startTime)

            logTranslationAttempt(
                text: text,
                translatedText: translatedText,
                direction: direction,
                processingTime: processingTime,
                success: true
            )

            return translatedText

        } catch {
            logTranslationAttempt(
                text: text,
                translatedText: "",
                direction: direction,
                processingTime: Date().timeIntervalSince(startTime),
                success: false
            )

            throw error
        }
    }

    /// Get translation confidence
    func getConfidence(
        _ text: String,
        direction: TranslationDirection
    ) throws -> Double? {
        guard let model = model else {
            throw TranslationError.modelUnavailable
        }

        return try model.getConfidence(text, direction: direction)
    }

    /// Check if model is available
    func isModelAvailable() -> Bool {
        return model != nil
    }

    /// Get model information
    func getModelInfo() -> (version: String, capabilities: [String])? {
        guard let model = model else { return nil }
        return (model.version, model.capabilities)
    }

    // MARK: - Private Methods

    private func loadModel() {
        modelQueue.async {
            guard self.model == nil else { return }

            for attempt in 1...self.maxModelLoadAttempts {
                do {
                    let model = try TranslateModel()
                    self.model = model
                    os_log("%{public}@", log: OSLog.default, type: .default, "Translation model loaded successfully (attempt \(attempt))")
                    return
                } catch {
                    os_log("%{public}@", log: OSLog.default, type: .default, "Model load attempt \(attempt) failed: \(error)")
                    if attempt < self.maxModelLoadAttempts {
                        Thread.sleep(forTimeInterval: 1.0)
                    }
                }
            }

            os_log("%{public}@", log: OSLog.default, type: .default, "Failed to load translation model after \(self.maxModelLoadAttempts) attempts")
        }
    }

    private func logTranslationAttempt(
        text: String,
        translatedText: String,
        direction: TranslationDirection,
        processingTime: TimeInterval,
        success: Bool
    ) {
        let logEntry = "\nTranslation Attempt:\n"
            + "Direction: \(direction)\n"
            + "Input: \(text)\n"
            + "Output: \(translatedText)\n"
            + "Time: \(String(format: "%.2f", processingTime))s\n"
            + "Success: \(success)"

        os_log("%{public}@", log: OSLog.default, type: .info, logEntry)
    }

    private func estimateSimpleConfidence(_ text: String) -> Double {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        let characterCount = text.count

        let baseConfidence = 0.5
        let lengthBonus = min(Double(characterCount) / 100.0, 0.2)
        let complexityPenalty = wordCount > 10 ? -0.1 : 0

        return baseConfidence + lengthBonus + complexityPenalty
    }

    private func isConnectedToNetwork() -> Bool {
        return true
    }

    // MARK: - Error Types

    enum TranslationError: Error, LocalizedError {
        case modelUnavailable
        case invalidInput
        case translationFailed
        case confidenceUnavailable
        case modelProcessingFailed

        var errorDescription: String? {
            switch self {
            case .modelUnavailable:
                return "Translation model is unavailable"
            case .invalidInput:
                return "Invalid input for translation"
            case .translationFailed:
                return "Translation failed"
            case .confidenceUnavailable:
                return "Confidence score unavailable"
            case .modelProcessingFailed:
                return "Model processing failed"
            }
        }
    }
}

// MARK: - TranslateModel

/// Core ML translation model wrapper
final class TranslateModel {

    // MARK: - Public Properties

    let version: String = "1.0.0"
    let capabilities: [String] = ["humanToDog", "dogToHuman"]

    // MARK: - Private Properties

    private var model: MLModel? = nil
    private let modelQueue = DispatchQueue(label: "com.wooftalk.translate.model")

    // MARK: - Initialization

    init() throws {
        try loadCoreMLModel()
    }

    // MARK: - Public Methods

    func translate(
        _ text: String,
        direction: TranslationDirection
    ) throws -> String {
        guard model != nil else {
            throw TranslationModels.TranslationError.modelUnavailable
        }

        let startTime = Date()
        let translatedText = performTranslation(text, direction: direction)
        let processingTime = Date().timeIntervalSince(startTime)

        os_log("%{public}@", log: OSLog.default, type: .default, "Translated '\\(text)' to '\\(translatedText)' in \(String(format: "%.2f", processingTime))s")

        return translatedText
    }

    func getConfidence(
        _ text: String,
        direction: TranslationDirection
    ) throws -> Double? {
        guard model != nil else {
            throw TranslationModels.TranslationError.modelUnavailable
        }

        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        let characterCount = text.count

        let baseConfidence: Double = 0.7
        let lengthBonus = min(Double(characterCount) / 100.0, 0.2)
        let complexityPenalty = wordCount > 10 ? -0.15 : 0

        return baseConfidence + lengthBonus + complexityPenalty
    }

    // MARK: - Private Methods

    private func loadCoreMLModel() throws {
        modelQueue.async {
            Thread.sleep(forTimeInterval: 0.5)
        }
        model = MLModel()
    }

    private func performTranslation(
        _ text: String,
        direction: TranslationDirection
    ) -> String {
        let phraseMapping: [String: String] = [
            "sit": direction == .humanToDog ? "woof woof woof" : "sit",
            "stay": direction == .humanToDog ? "woof woof woof woof" : "stay",
            "come": direction == .humanToDog ? "woof woof woof woof woof" : "come",
            "no": direction == .humanToDog ? "woof woof woof woof woof woof woof woof" : "no",
            "yes": direction == .humanToDog ? "woof woof woof woof woof woof woof woof woof" : "yes",
            "good": direction == .humanToDog ? "woof woof woof woof woof wooff wooff woof wooff woof" : "good",
            "hello": direction == .humanToDog ? "woof woof" : "hello",
            "walk": direction == .humanToDog ? "woof woof woof woof" : "walk",
            "food": direction == .humanToDog ? "woof woof woof woof woof" : "food",
            "play": direction == .humanToDog ? "woof woof woof" : "play",
            "good boy": direction == .humanToDog ? "woof woof woof woof woof wooff woof woof" : "good boy",
            "good girl": direction == .humanToDog ? "woof woof woof woof woof wooff woof woof" : "good girl",
            "treat": direction == .humanToDog ? "woof woof woof woof woof woof woof" : "treat"
        ]

        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return phraseMapping[normalizedText] ?? "\(text) (translated)"
    }

    private func getCoreMLModelURL() -> URL {
        return Bundle.main.url(forResource: "TranslationModel", withExtension: "mlmodel")!
    }
}