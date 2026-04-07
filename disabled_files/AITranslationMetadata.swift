import Foundation
import CoreData

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
    private enum Keys {
        static let translationMode = "com.wooftalk.translationMode"
        static let aiModelEnabled = "com.wooftalk.aiModelEnabled"
        static let lastTranslationMetadata = "com.wooftalk.lastTranslationMetadata"
    }
    
    var translationMode: TranslationMode {
        get {
            guard let rawValue = string(forKey: Keys.translationMode),
                  let mode = TranslationMode(rawValue: rawValue) else {
                return .ruleBased
            }
            return mode
        }
        set {
            set(newValue.rawValue, forKey: Keys.translationMode)
        }
    }
    
    var aiModelEnabled: Bool {
        get { bool(forKey: Keys.aiModelEnabled) }
        set { set(newValue, forKey: Keys.aiModelEnabled) }
    }
    
    func saveTranslationMetadata(_ metadata: AITranslationMetadata) {
        if let encoded = try? JSONEncoder().encode(metadata) {
            set(encoded, forKey: Keys.lastTranslationMetadata)
        }
    }
    
    func getLastTranslationMetadata() -> AITranslationMetadata? {
        guard let data = data(forKey: Keys.lastTranslationMetadata),
              let metadata = try? JSONDecoder().decode(AITranslationMetadata.self, from: data) else {
            return nil
        }
        return metadata
    }
}