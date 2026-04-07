// MARK: - Analytics Aggregator

import Foundation

final class AnalyticsAggregator {
    
    private let qualityCollector: QualityMetricsCollector
    private let usageTracker: UsageAnalyticsTracker
    private let performanceMonitor: PerformanceMonitor
    private let eventStore: AnalyticsEventStore
    
    init(
        qualityCollector: QualityMetricsCollector,
        usageTracker: UsageAnalyticsTracker,
        performanceMonitor: PerformanceMonitor,
        eventStore: AnalyticsEventStore
    ) {
        self.qualityCollector = qualityCollector
        self.usageTracker = usageTracker
        self.performanceMonitor = performanceMonitor
        self.eventStore = eventStore
    }
    
    // MARK: - Dashboard Summary
    
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
    
    // MARK: - Comprehensive Reports
    
    func getQualityReport(since date: Date? = nil) -> QualityReport {
        let stats = qualityCollector.getQualityStatistics(since: date)
        let trend = qualityCollector.getQualityTrend(days: 7)
        
        return QualityReport(
            statistics: stats,
            trend: trend,
            generatedAt: Date()
        )
    }
    
    func getPerformanceReport(since date: Date? = nil) -> PerformanceReport {
        let stats = performanceMonitor.getPerformanceStatistics(since: date)
        let trend = performanceMonitor.getLatencyTrend(days: 7)
        let breakdown = performanceMonitor.getTranslationTypeBreakdown()
        
        return PerformanceReport(
            statistics: stats,
            trend: trend,
            translationTypeBreakdown: breakdown,
            generatedAt: Date()
        )
    }
    
    func getUsageReport() -> UsageReport {
        let features = usageTracker.getTopFeatures(limit: 10)
        let languagePairs = usageTracker.getTopLanguagePairs(limit: 5)
        let dailyUsage = usageTracker.getDailyUsage(days: 7)
        
        return UsageReport(
            topFeatures: features,
            topLanguagePairs: languagePairs,
            dailyUsage: dailyUsage,
            totalTranslations: usageTracker.getTotalTranslationCount(),
            weeklyUsage: usageTracker.getWeeklyUsage(),
            monthlyUsage: usageTracker.getMonthlyUsage(),
            generatedAt: Date()
        )
    }
    
    // MARK: - Real-time Data
    
    func getRealtimeMetrics() -> RealtimeMetrics {
        let now = Date()
        let lastHour = now.addingTimeInterval(-3600)
        
        return RealtimeMetrics(
            translationsLastHour: eventStore.getEventCount(since: lastHour),
            averageLatencyMs: performanceMonitor.getAverageLatency(since: lastHour),
            successRate: performanceMonitor.getSuccessRate(since: lastHour),
            activeFeatures: usageTracker.getActiveFeatureCount(),
            timestamp: now
        )
    }
}

// MARK: - Report Types

struct QualityReport {
    let statistics: QualityStatistics
    let trend: [QualityStatistics]
    let generatedAt: Date
}

struct PerformanceReport {
    let statistics: PerformanceStatistics
    let trend: [PerformanceStatistics]
    let translationTypeBreakdown: [TranslationType: Int]
    let generatedAt: Date
}

struct UsageReport {
    let topFeatures: [FeatureUsageStats]
    let topLanguagePairs: [LanguagePairUsage]
    let dailyUsage: [Date: Int]
    let totalTranslations: Int
    let weeklyUsage: Int
    let monthlyUsage: Int
    let generatedAt: Date
}

struct RealtimeMetrics {
    let translationsLastHour: Int
    let averageLatencyMs: Double
    let successRate: Double
    let activeFeatures: Int
    let timestamp: Date
}
