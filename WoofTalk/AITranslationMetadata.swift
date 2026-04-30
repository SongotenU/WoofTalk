import Foundation

struct AITranslationMetadata: Codable {
    let translationMode: String
    let confidence: Double
    let qualityTier: String
    let modelVersion: String
    let inferenceTimeMs: Double
    let timestamp: Date

    init(mode: TranslationMode, qualityScore: TranslationQualityScore, inferenceTime: TimeInterval) {
        self.translationMode = mode.rawValue
        self.confidence = qualityScore.confidence
        self.qualityTier = qualityScore.qualityTier.rawValue
        self.modelVersion = "1.0.0"
        self.inferenceTimeMs = inferenceTime * 1000
        self.timestamp = Date()
    }

    var confidencePercentage: Int { Int(confidence * 100) }

    var confidenceDescription: String {
        switch confidence {
        case 0.8...: return "High"
        case 0.6..<0.8: return "Medium"
        case 0.4..<0.6: return "Low"
        default: return "Very Low"
        }
    }
}

struct TranslationConfidence {
    let score: Double
    let tier: TranslationQualityScore.QualityTier
    let description: String

    init(confidence: Double) {
        self.score = confidence
        self.tier = TranslationQualityScore(confidence: confidence).qualityTier
        switch tier {
        case .high: self.description = "High confidence translation"
        case .medium: self.description = "Medium confidence - may need verification"
        case .low: self.description = "Low confidence - please verify"
        case .veryLow: self.description = "Very low confidence - review needed"
        }
    }

    var percentage: Int { Int(score * 100) }
    var colorName: String { tier.color }
}

extension UserDefaults {
    var translationMode: TranslationMode {
        get { TranslationMode(rawValue: string(forKey: "com.wooftalk.translationMode") ?? "") ?? .ruleBased }
        set { set(newValue.rawValue, forKey: "com.wooftalk.translationMode") }
    }

    var aiModelEnabled: Bool {
        get { bool(forKey: "com.wooftalk.aiModelEnabled") }
        set { set(newValue, forKey: "com.wooftalk.aiModelEnabled") }
    }

    func saveTranslationMetadata(_ metadata: AITranslationMetadata) {
        if let encoded = try? JSONEncoder().encode(metadata) {
            set(encoded, forKey: "com.wooftalk.lastTranslationMetadata")
        }
    }

    func getLastTranslationMetadata() -> AITranslationMetadata? {
        guard let data = data(forKey: "com.wooftalk.lastTranslationMetadata"),
              let metadata = try? JSONDecoder().decode(AITranslationMetadata.self, from: data) else {
            return nil
        }
        return metadata
    }
}
