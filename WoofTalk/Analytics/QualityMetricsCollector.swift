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
                "confidence": String(confidence),
                "estimatedAccuracy": String(estimatedAccuracy),
                "qualityTier": metrics.qualityTier,
                "modelVersion": modelVersion
            ]
        )
        eventStore.recordEvent(event)
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

        let tierCounts = metrics.reduce(into: (high: 0, medium: 0, low: 0, veryLow: 0)) { result, metric in
            switch AnalyticsQualityTier.from(confidence: metric.confidence) {
            case .high: result.high += 1
            case .medium: result.medium += 1
            case .low: result.low += 1
            case .veryLow: result.veryLow += 1
            }
        }

        return QualityStatistics(
            totalTranslations: totalCount,
            averageConfidence: metrics.reduce(0) { $0 + $1.confidence } / Double(totalCount),
            medianConfidence: confidences[confidences.count / 2],
            averageAccuracy: metrics.reduce(0) { $0 + $1.estimatedAccuracy } / Double(totalCount),
            highQualityCount: tierCounts.high,
            mediumQualityCount: tierCounts.medium,
            lowQualityCount: tierCounts.low,
            veryLowQualityCount: tierCounts.veryLow,
            periodStart: date ?? Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            periodEnd: Date()
        )
    }
    
    func getAverageQualityScore(since date: Date? = nil) -> Double {
        return getQualityStatistics(since: date).averageConfidence
    }
    
    func getQualityTrend(days: Int = 7) -> [QualityStatistics] {
        (0..<days).reversed().compactMap { dayOffset in
            guard let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) else { return nil }
            return getQualityStatistics(since: Calendar.current.startOfDay(for: date))
        }
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
        (try? storage.load(forKey: AnalyticsStorageKey.qualityMetrics.rawValue)) ?? []
    }
}
