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
