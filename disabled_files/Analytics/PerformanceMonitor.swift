// MARK: - Performance Monitor

import Foundation

final class PerformanceMonitor {
    
    private let storage: AnalyticsStorage
    private let eventStore: AnalyticsEventStore
    private let lock = NSLock()
    
    private var performanceMetrics: [TranslationPerformanceMetrics] = []
    private let maxStoredMetrics = 5000
    
    private var latencyThresholdMs: Double = 1000.0
    
    init(storage: AnalyticsStorage = UserDefaultsAnalyticsStorage(), eventStore: AnalyticsEventStore) {
        self.storage = storage
        self.eventStore = eventStore
        loadMetrics()
    }
    
    // MARK: - Recording Methods
    
    func recordLatency(
        latencyMs: Double,
        success: Bool,
        translationType: TranslationType,
        languageDirection: String,
        sessionId: String
    ) {
        lock.lock()
        defer { lock.unlock() }
        
        let metrics = TranslationPerformanceMetrics(
            latencyMs: latencyMs,
            success: success,
            translationType: translationType,
            languageDirection: languageDirection
        )
        
        performanceMetrics.append(metrics)
        
        if performanceMetrics.count > maxStoredMetrics {
            performanceMetrics = Array(performanceMetrics.suffix(maxStoredMetrics))
        }
        
        saveMetrics()
        
        let event = TranslationAnalyticsEvent(
            eventType: .latencyMeasured,
            sessionId: sessionId,
            metadata: [
                "latencyMs": String(latencyMs),
                "success": String(success),
                "translationType": translationType.rawValue,
                "languageDirection": languageDirection
            ]
        )
        eventStore.recordEvent(event)
    }
    
    func recordSuccess(
        latencyMs: Double,
        translationType: TranslationType = .batch,
        languageDirection: String = "humanToDog",
        sessionId: String
    ) {
        recordLatency(latencyMs: latencyMs, success: true, translationType: translationType, languageDirection: languageDirection, sessionId: sessionId)
    }
    
    func recordFailure(
        latencyMs: Double = 0,
        translationType: TranslationType = .batch,
        languageDirection: String = "humanToDog",
        sessionId: String,
        errorDescription: String? = nil
    ) {
        recordLatency(latencyMs: latencyMs, success: false, translationType: translationType, languageDirection: languageDirection, sessionId: sessionId)
        
        if let error = errorDescription {
            let event = TranslationAnalyticsEvent(
                eventType: .errorOccurred,
                sessionId: sessionId,
                metadata: ["error": error]
            )
            eventStore.recordEvent(event)
        }
    }
    
    // MARK: - Threshold Management
    
    func setLatencyThreshold(_ thresholdMs: Double) {
        latencyThresholdMs = thresholdMs
    }
    
    func getLatencyThreshold() -> Double {
        return latencyThresholdMs
    }
    
    func isWithinThreshold(_ latencyMs: Double) -> Bool {
        return latencyMs < latencyThresholdMs
    }
    
    // MARK: - Query Methods
    
    func getPerformanceStatistics(since date: Date? = nil) -> PerformanceStatistics {
        lock.lock()
        defer { lock.unlock() }
        
        var metrics = performanceMetrics
        
        if let date = date {
            metrics = metrics.filter { $0.timestamp >= date }
        }
        
        guard !metrics.isEmpty else {
            return PerformanceStatistics(
                totalTranslations: 0,
                successfulTranslations: 0,
                failedTranslations: 0,
                minLatencyMs: 0,
                maxLatencyMs: 0,
                averageLatencyMs: 0,
                p50LatencyMs: 0,
                p95LatencyMs: 0,
                p99LatencyMs: 0,
                periodStart: date ?? Date(),
                periodEnd: Date()
            )
        }
        
        let sortedLatencies = metrics.map { $0.latencyMs }.sorted()
        let totalCount = metrics.count
        let successfulCount = metrics.filter { $0.success }.count
        let failedCount = totalCount - successfulCount
        
        return PerformanceStatistics(
            totalTranslations: totalCount,
            successfulTranslations: successfulCount,
            failedTranslations: failedCount,
            minLatencyMs: sortedLatencies.first ?? 0,
            maxLatencyMs: sortedLatencies.last ?? 0,
            averageLatencyMs: sortedLatencies.reduce(0, +) / Double(totalCount),
            p50LatencyMs: percentile(sortedLatencies, p: 0.5),
            p95LatencyMs: percentile(sortedLatencies, p: 0.95),
            p99LatencyMs: percentile(sortedLatencies, p: 0.99),
            periodStart: date ?? Date().addingTimeInterval(-86400),
            periodEnd: Date()
        )
    }
    
    func getAverageLatency(since date: Date? = nil) -> Double {
        return getPerformanceStatistics(since: date).averageLatencyMs
    }
    
    func getSuccessRate(since date: Date? = nil) -> Double {
        return getPerformanceStatistics(since: date).successRate
    }
    
    func getLatencyTrend(days: Int = 7) -> [PerformanceStatistics] {
        var trends: [PerformanceStatistics] = []
        let calendar = Calendar.current
        
        for dayOffset in (0..<days).reversed() {
            let startOfDay = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            let stats = getPerformanceStatistics(since: startOfDay)
            trends.append(stats)
        }
        
        return trends
    }
    
    func getTranslationTypeBreakdown() -> [TranslationType: Int] {
        lock.lock()
        defer { lock.unlock() }
        
        var breakdown: [TranslationType: Int] = [:]
        
        for metrics in performanceMetrics {
            breakdown[metrics.translationType, default: 0] += 1
        }
        
        return breakdown
    }
    
    // MARK: - Clear Data
    
    func clearMetrics() {
        lock.lock()
        defer { lock.unlock() }
        
        performanceMetrics = []
        try? storage.remove(forKey: AnalyticsStorageKey.performanceMetrics.rawValue)
    }
    
    // MARK: - Private Methods
    
    private func percentile(_ sortedValues: [Double], p: Double) -> Double {
        guard !sortedValues.isEmpty else { return 0 }
        
        let index = Int(Double(sortedValues.count - 1) * p)
        return sortedValues[min(index, sortedValues.count - 1)]
    }
    
    private func saveMetrics() {
        try? storage.save(performanceMetrics, forKey: AnalyticsStorageKey.performanceMetrics.rawValue)
    }
    
    private func loadMetrics() {
        if let metrics: [TranslationPerformanceMetrics] = try? storage.load(forKey: AnalyticsStorageKey.performanceMetrics.rawValue) {
            performanceMetrics = metrics
        }
    }
}
