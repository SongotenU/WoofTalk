// MARK: - Translation Analytics Models

import Foundation
import AVFoundation

enum AnalyticsEventType: String, Codable, CaseIterable {
    case translationCompleted = "translation_completed"
    case qualityScoreRecorded = "quality_score_recorded"
    case latencyMeasured = "latency_measured"
    case featureUsed = "feature_used"
    case errorOccurred = "error_occurred"
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case languageChanged = "language_changed"
    case modelLoaded = "model_loaded"
    case modelUnloaded = "model_unloaded"
}

enum TranslationType: String, Codable, CaseIterable {
    case humanToAnimal = "human_to_animal"
    case animalToHuman = "animal_to_human"
    case realTime = "real_time"
    case streaming = "streaming"
    case batch = "batch"
}

enum AnalyticsQualityTier: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case veryLow = "Very Low"
    
    static func from(confidence: Double) -> AnalyticsQualityTier {
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
}

struct TranslationAnalyticsEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let eventType: AnalyticsEventType
    let sessionId: String
    let metadata: [String: String]
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        eventType: AnalyticsEventType,
        sessionId: String,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.sessionId = sessionId
        self.metadata = metadata
    }
}

struct TranslationQualityMetrics: Codable {
    let confidence: Double
    let estimatedAccuracy: Double
    let qualityTier: String
    let modelVersion: String
    let timestamp: Date
    
    init(from confidence: Double, estimatedAccuracy: Double, modelVersion: String) {
        self.confidence = confidence
        self.estimatedAccuracy = estimatedAccuracy
        self.qualityTier = AnalyticsQualityTier.from(confidence: confidence).rawValue
        self.modelVersion = modelVersion
        self.timestamp = Date()
    }
    
    init(confidence: Double, estimatedAccuracy: Double, qualityTier: String, modelVersion: String) {
        self.confidence = confidence
        self.estimatedAccuracy = estimatedAccuracy
        self.qualityTier = qualityTier
        self.modelVersion = modelVersion
        self.timestamp = Date()
    }
}

struct QualityStatistics: Codable {
    let totalTranslations: Int
    let averageConfidence: Double
    let medianConfidence: Double
    let averageAccuracy: Double
    let highQualityCount: Int
    let mediumQualityCount: Int
    let lowQualityCount: Int
    let veryLowQualityCount: Int
    let periodStart: Date
    let periodEnd: Date
    
    var highQualityPercentage: Double {
        guard totalTranslations > 0 else { return 0 }
        return Double(highQualityCount) / Double(totalTranslations) * 100
    }
}

// MARK: - Performance Metrics

struct TranslationPerformanceMetrics: Codable {
    let latencyMs: Double
    let success: Bool
    let translationType: TranslationType
    let languageDirection: String
    let timestamp: Date
    
    init(
        latencyMs: Double,
        success: Bool,
        translationType: TranslationType,
        languageDirection: String
    ) {
        self.latencyMs = latencyMs
        self.success = success
        self.translationType = translationType
        self.languageDirection = languageDirection
        self.timestamp = Date()
    }
}

struct PerformanceStatistics: Codable {
    let totalTranslations: Int
    let successfulTranslations: Int
    let failedTranslations: Int
    let minLatencyMs: Double
    let maxLatencyMs: Double
    let averageLatencyMs: Double
    let p50LatencyMs: Double
    let p95LatencyMs: Double
    let p99LatencyMs: Double
    let periodStart: Date
    let periodEnd: Date
    
    var successRate: Double {
        guard totalTranslations > 0 else { return 0 }
        return Double(successfulTranslations) / Double(totalTranslations) * 100
    }
}

// MARK: - Usage Statistics

struct FeatureUsageStats: Codable, Identifiable {
    let id: UUID
    let featureName: String
    var usageCount: Int
    var lastUsed: Date
    var totalSessionDuration: TimeInterval
    
    init(featureName: String) {
        self.id = UUID()
        self.featureName = featureName
        self.usageCount = 0
        self.lastUsed = Date()
        self.totalSessionDuration = 0
    }
    
    mutating func recordUsage(sessionDuration: TimeInterval = 0) {
        usageCount += 1
        lastUsed = Date()
        totalSessionDuration += sessionDuration
    }
}

struct LanguagePairUsage: Codable, Identifiable {
    let id: UUID
    let sourceLanguage: String
    let targetLanguage: String
    var usageCount: Int
    var lastUsed: Date
    
    init(sourceLanguage: String, targetLanguage: String) {
        self.id = UUID()
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.usageCount = 0
        self.lastUsed = Date()
    }
    
    mutating func recordUsage() {
        usageCount += 1
        lastUsed = Date()
    }
}

// MARK: - Session Analytics

struct SessionAnalytics: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var translationCount: Int
    var totalTranslationDuration: TimeInterval
    var featuresUsed: [String]
    
    init() {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.translationCount = 0
        self.totalTranslationDuration = 0
        self.featuresUsed = []
    }
    
    mutating func endSession() {
        endTime = Date()
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}

// MARK: - Dashboard Summary

struct AnalyticsDashboardSummary: Codable {
    let translationCount: Int
    let averageQualityScore: Double
    let averageLatencyMs: Double
    let successRate: Double
    let activeFeatures: Int
    let topLanguagePairs: [LanguagePairUsage]
    let periodStart: Date
    let periodEnd: Date
    let generatedAt: Date
    
    init(
        translationCount: Int,
        averageQualityScore: Double,
        averageLatencyMs: Double,
        successRate: Double,
        activeFeatures: Int,
        topLanguagePairs: [LanguagePairUsage]
    ) {
        self.translationCount = translationCount
        self.averageQualityScore = averageQualityScore
        self.averageLatencyMs = averageLatencyMs
        self.successRate = successRate
        self.activeFeatures = activeFeatures
        self.topLanguagePairs = topLanguagePairs
        self.periodStart = Date().addingTimeInterval(-86400) // Last 24 hours
        self.periodEnd = Date()
        self.generatedAt = Date()
    }
}
