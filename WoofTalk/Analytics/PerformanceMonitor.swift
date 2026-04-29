import Foundation

final class PerformanceMonitor {
    private let storage: AnalyticsStorage
    private let eventStore: AnalyticsEventStore
    private let lock = NSLock()
    private var metrics: [TranslationPerformanceMetrics] = []
    private let maxStored = 5000
    private var latencyThresholdMs: Double = 1000

    init(storage: AnalyticsStorage = UserDefaultsAnalyticsStorage(), eventStore: AnalyticsEventStore) {
        self.storage = storage
        self.eventStore = eventStore
        if let saved: [TranslationPerformanceMetrics] = try? storage.load(forKey: AnalyticsStorageKey.performanceMetrics.rawValue) {
            metrics = saved
        }
    }

    func recordLatency(latencyMs: Double, success: Bool, translationType: TranslationType, languageDirection: String, sessionId: String) {
        lock.lock(); defer { lock.unlock() }
        let m = TranslationPerformanceMetrics(latencyMs: latencyMs, success: success, translationType: translationType, languageDirection: languageDirection)
        metrics.append(m)
        if metrics.count > maxStored { metrics = Array(metrics.suffix(maxStored)) }
        try? storage.save(metrics, forKey: AnalyticsStorageKey.performanceMetrics.rawValue)
        eventStore.recordEvent(TranslationAnalyticsEvent(eventType: .latencyMeasured, sessionId: sessionId, metadata: [
            "latencyMs": String(latencyMs), "success": String(success),
            "translationType": translationType.rawValue, "languageDirection": languageDirection
        ]))
    }

    func recordSuccess(latencyMs: Double, translationType: TranslationType = .batch, languageDirection: String = "humanToDog", sessionId: String) {
        recordLatency(latencyMs: latencyMs, success: true, translationType: translationType, languageDirection: languageDirection, sessionId: sessionId)
    }

    func recordFailure(latencyMs: Double = 0, translationType: TranslationType = .batch, languageDirection: String = "humanToDog", sessionId: String, errorDescription: String? = nil) {
        recordLatency(latencyMs: latencyMs, success: false, translationType: translationType, languageDirection: languageDirection, sessionId: sessionId)
        if let error = errorDescription {
            eventStore.recordEvent(TranslationAnalyticsEvent(eventType: .errorOccurred, sessionId: sessionId, metadata: ["error": error]))
        }
    }

    func setLatencyThreshold(_ ms: Double) { latencyThresholdMs = ms }
    func getLatencyThreshold() -> Double { latencyThresholdMs }
    func isWithinThreshold(_ ms: Double) -> Bool { ms < latencyThresholdMs }

    func getPerformanceStatistics(since date: Date? = nil) -> PerformanceStatistics {
        lock.lock(); defer { lock.unlock() }
        let filtered = date.map { metrics.filter { $0.timestamp >= $0 } } ?? metrics
        guard !filtered.isEmpty else {
            return PerformanceStatistics(totalTranslations: 0, successfulTranslations: 0, failedTranslations: 0, minLatencyMs: 0, maxLatencyMs: 0, averageLatencyMs: 0, p50LatencyMs: 0, p95LatencyMs: 0, p99LatencyMs: 0, periodStart: date ?? Date(), periodEnd: Date())
        }
        let sorted = filtered.map { $0.latencyMs }.sorted()
        let total = filtered.count
        let successCount = filtered.filter { $0.success }.count
        let sum = sorted.reduce(0, +)
        return PerformanceStatistics(
            totalTranslations: total, successfulTranslations: successCount, failedTranslations: total - successCount,
            minLatencyMs: sorted.first!, maxLatencyMs: sorted.last!,
            averageLatencyMs: sum / Double(total),
            p50LatencyMs: percentile(sorted, p: 0.5), p95LatencyMs: percentile(sorted, p: 0.95), p99LatencyMs: percentile(sorted, p: 0.99),
            periodStart: date ?? Calendar.current.date(byAdding: .day, value: -1, to: Date())!, periodEnd: Date()
        )
    }

    func getAverageLatency(since date: Date? = nil) -> Double { getPerformanceStatistics(since: date).averageLatencyMs }
    func getSuccessRate(since date: Date? = nil) -> Double { getPerformanceStatistics(since: date).successRate }

    func getLatencyTrend(days: Int = 7) -> [PerformanceStatistics] {
        (0..<days).reversed().compactMap { offset in
            guard let start = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return getPerformanceStatistics(since: Calendar.current.startOfDay(for: start))
        }
    }

    func getTranslationTypeBreakdown() -> [TranslationType: Int] {
        lock.lock(); defer { lock.unlock() }
        var result: [TranslationType: Int] = [:]
        for m in metrics { result[m.translationType, default: 0] += 1 }
        return result
    }

    func clearMetrics() {
        lock.lock(); defer { lock.unlock() }
        metrics = []
        try? storage.remove(forKey: AnalyticsStorageKey.performanceMetrics.rawValue)
    }

    private func percentile(_ sorted: [Double], p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        return sorted[min(Int(Double(sorted.count - 1) * p), sorted.count - 1)]
    }
}
