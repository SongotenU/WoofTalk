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
