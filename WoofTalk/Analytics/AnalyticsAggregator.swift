import Foundation

final class AnalyticsAggregator {
    private let qualityCollector: QualityMetricsCollector
    private let usageTracker: UsageAnalyticsTracker
    private let performanceMonitor: PerformanceMonitor
    private let eventStore: AnalyticsEventStore

    init(qualityCollector: QualityMetricsCollector, usageTracker: UsageAnalyticsTracker,
         performanceMonitor: PerformanceMonitor, eventStore: AnalyticsEventStore) {
        self.qualityCollector = qualityCollector
        self.usageTracker = usageTracker
        self.performanceMonitor = performanceMonitor
        self.eventStore = eventStore
    }

    func getDashboardSummary(since date: Date? = nil) -> AnalyticsDashboardSummary {
        let qualityStats = qualityCollector.getQualityStatistics(since: date)
        let performanceStats = performanceMonitor.getPerformanceStatistics(since: date)

        return AnalyticsDashboardSummary(
            translationCount: usageTracker.getTotalTranslationCount(),
            averageQualityScore: qualityStats.averageConfidence,
            averageLatencyMs: performanceStats.averageLatencyMs,
            successRate: performanceStats.successRate,
            activeFeatures: usageTracker.getActiveFeatureCount(),
            topLanguagePairs: usageTracker.getTopLanguagePairs()
        )
    }

    func getQualityReport(since date: Date? = nil) -> QualityReport {
        QualityReport(
            statistics: qualityCollector.getQualityStatistics(since: date),
            trend: qualityCollector.getQualityTrend(days: 7),
            generatedAt: Date()
        )
    }

    func getPerformanceReport(since date: Date? = nil) -> PerformanceReport {
        PerformanceReport(
            statistics: performanceMonitor.getPerformanceStatistics(since: date),
            events: eventStore.getEvents(since: date, eventType: .performance),
            generatedAt: Date()
        )
    }

    func getUsageReport(since date: Date? = nil) -> UsageReport {
        UsageReport(
            totalTranslations: usageTracker.getTotalTranslationCount(since: date),
            translationsByMode: usageTracker.getTranslationsByMode(since: date),
            activeUsers: usageTracker.getActiveUserCount(since: date),
            topLanguagePairs: usageTracker.getTopLanguagePairs(limit: 10),
            generatedAt: Date()
        )
    }

    func getComprehensiveReport(since date: Date? = nil) -> ComprehensiveAnalyticsReport {
        ComprehensiveAnalyticsReport(
            dashboard: getDashboardSummary(since: date),
            qualityReport: getQualityReport(since: date),
            performanceReport: getPerformanceReport(since: date),
            usageReport: getUsageReport(since: date),
            generatedAt: Date()
        )
    }
}
