// MARK: - Quality Metrics Collector

import Foundation

final class QualityMetricsCollector {
    
    private let storage: AnalyticsStorage
    private let eventStore: AnalyticsEventStore
    private let lock = NSLock()
    
    private var recentMetrics: [TranslationQualityMetrics] = []
    private let maxStoredMetrics = 1000
    
    init(storage: AnalyticsStorage = UserDefaultsAnalyticsStorage(), eventStore: AnalyticsEventStore) {
        self.storage = storage
        self.eventStore = eventStore
    }
    
    // MARK: - Recording Methods
    
    func recordQualityMetrics(_ metrics: TranslationQualityMetrics, sessionId: String) {
        lock.lock()
        defer { lock.unlock() }
        
        recentMetrics.append(metrics)
        
        if recentMetrics.count > maxStoredMetrics {
            recentMetrics = Array(recentMetrics.suffix(maxStoredMetrics))
        }
        
        saveMetrics()
        
        let event = TranslationAnalyticsEvent(
            eventType: .qualityScoreRecorded,
            sessionId: sessionId,
            metadata: [
                "confidence": String(metrics.confidence),
                "estimatedAccuracy": String(metrics.estimatedAccuracy),
                "qualityTier": metrics.qualityTier,
                "modelVersion": metrics.modelVersion
            ]
        )
        eventStore.recordEvent(event)
    }
    
    func recordTranslationQuality(
        confidence: Double,
        estimatedAccuracy: Double,
        modelVersion: String,
        sessionId: String
    ) {
        let metrics = TranslationQualityMetrics(
            from: confidence,
            estimatedAccuracy: estimatedAccuracy,
            modelVersion: modelVersion
        )
        recordQualityMetrics(metrics, sessionId: sessionId)
    }
    
    // MARK: - Query Methods
    
    func getQualityStatistics(since date: Date? = nil) -> QualityStatistics {
        lock.lock()
        defer { lock.unlock() }
        
        var metrics = loadMetrics()
        
        if let date = date {
            metrics = metrics.filter { $0.timestamp >= date }
        }
        
        guard !metrics.isEmpty else {
            return QualityStatistics(
                totalTranslations: 0,
                averageConfidence: 0,
                medianConfidence: 0,
                averageAccuracy: 0,
                highQualityCount: 0,
                mediumQualityCount: 0,
                lowQualityCount: 0,
                veryLowQualityCount: 0,
                periodStart: date ?? Date(),
                periodEnd: Date()
            )
        }
        
        let confidences = metrics.map { $0.confidence }.sorted()
        let totalCount = metrics.count
        
        let highCount = metrics.filter { AnalyticsQualityTier.from(confidence: $0.confidence) == .high }.count
        let mediumCount = metrics.filter { AnalyticsQualityTier.from(confidence: $0.confidence) == .medium }.count
        let lowCount = metrics.filter { AnalyticsQualityTier.from(confidence: $0.confidence) == .low }.count
        let veryLowCount = metrics.filter { AnalyticsQualityTier.from(confidence: $0.confidence) == .veryLow }.count
        
        return QualityStatistics(
            totalTranslations: totalCount,
            averageConfidence: metrics.reduce(0, { $0 + $1.confidence }) / Double(totalCount),
            medianConfidence: confidences[confidences.count / 2],
            averageAccuracy: metrics.reduce(0, { $0 + $1.estimatedAccuracy }) / Double(totalCount),
            highQualityCount: highCount,
            mediumQualityCount: mediumCount,
            lowQualityCount: lowCount,
            veryLowQualityCount: veryLowCount,
            periodStart: date ?? Date().addingTimeInterval(-86400),
            periodEnd: Date()
        )
    }
    
    func getAverageQualityScore(since date: Date? = nil) -> Double {
        return getQualityStatistics(since: date).averageConfidence
    }
    
    func getQualityTrend(days: Int = 7) -> [QualityStatistics] {
        var trends: [QualityStatistics] = []
        let calendar = Calendar.current
        
        for dayOffset in (0..<days).reversed() {
            let startOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            let stats = getQualityStatistics(since: startOfDay)
            trends.append(stats)
        }
        
        return trends
    }
    
    // MARK: - Storage
    
    func clearMetrics() {
        lock.lock()
        defer { lock.unlock() }
        
        recentMetrics = []
        try? storage.remove(forKey: AnalyticsStorageKey.qualityMetrics.rawValue)
    }
    
    // MARK: - Private Methods
    
    private func saveMetrics() {
        try? storage.save(recentMetrics, forKey: AnalyticsStorageKey.qualityMetrics.rawValue)
    }
    
    private func loadMetrics() -> [TranslationQualityMetrics] {
        guard let metrics: [TranslationQualityMetrics] = try? storage.load(forKey: AnalyticsStorageKey.qualityMetrics.rawValue) else {
            return []
        }
        return metrics
    }
}
