// MARK: - Translation Analytics Service

import Foundation

final class TranslationAnalyticsService {
    
    // MARK: - Singleton
    
    static let shared = TranslationAnalyticsService()
    
    // MARK: - Components
    
    let storage: AnalyticsStorage
    let eventStore: AnalyticsEventStore
    let qualityCollector: QualityMetricsCollector
    let usageTracker: UsageAnalyticsTracker
    let performanceMonitor: PerformanceMonitor
    let aggregator: AnalyticsAggregator
    let reportGenerator: AnalyticsReportGenerator
    
    // MARK: - State
    
    private(set) var currentSessionId: String?
    private var isSessionActive = false
    private let sessionLock = NSLock()
    
    // MARK: - Initialization
    
    private init() {
        self.storage = UserDefaultsAnalyticsStorage()
        self.eventStore = AnalyticsEventStore(storage: storage)
        self.qualityCollector = QualityMetricsCollector(storage: storage, eventStore: eventStore)
        self.usageTracker = UsageAnalyticsTracker(storage: storage, eventStore: eventStore)
        self.performanceMonitor = PerformanceMonitor(storage: storage, eventStore: eventStore)
        self.aggregator = AnalyticsAggregator(
            qualityCollector: qualityCollector,
            usageTracker: usageTracker,
            performanceMonitor: performanceMonitor,
            eventStore: eventStore
        )
        self.reportGenerator = AnalyticsReportGenerator(aggregator: aggregator)
    }
    
    // MARK: - Session Management
    
    func startSession() -> String {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        
        guard !isSessionActive else {
            return currentSessionId ?? ""
        }
        
        let sessionId = usageTracker.startSession()
        currentSessionId = sessionId
        isSessionActive = true
        
        return sessionId
    }
    
    func endSession() {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        
        guard isSessionActive else { return }
        
        usageTracker.endSession()
        currentSessionId = nil
        isSessionActive = false
    }
    
    // MARK: - Translation Tracking
    
    func trackTranslation(
        quality: (confidence: Double, estimatedAccuracy: Double, modelVersion: String),
        latencyMs: Double,
        success: Bool,
        translationType: TranslationType = .batch,
        languageDirection: String = "humanToDog"
    ) {
        guard let sessionId = currentSessionId else { return }
        
        qualityCollector.recordTranslationQuality(
            confidence: quality.confidence,
            estimatedAccuracy: quality.estimatedAccuracy,
            modelVersion: quality.modelVersion,
            sessionId: sessionId
        )
        
        performanceMonitor.recordLatency(
            latencyMs: latencyMs,
            success: success,
            translationType: translationType,
            languageDirection: languageDirection,
            sessionId: sessionId
        )
        
        usageTracker.recordTranslation(sessionId: sessionId, duration: latencyMs / 1000)
        
        let direction = languageDirection.contains("ToDog") || languageDirection == "humanToAnimal" ? "human" : "animal"
        usageTracker.recordLanguagePairUsage(
            sourceLanguage: direction,
            targetLanguage: direction == "human" ? "animal" : "human",
            sessionId: sessionId
        )
    }
    
    func trackFeatureUsage(featureName: String) {
        guard let sessionId = currentSessionId else { return }
        usageTracker.recordFeatureUsage(featureName: featureName, sessionId: sessionId)
    }
    
    // MARK: - Integration with AITranslationService
    
    func trackAITranslation(result: AITranslationResult, latencyMs: Double, translationType: TranslationType = .batch, direction: TranslationDirection = .humanToDog) {
        let languageDir = direction == .humanToDog ? "humanToDog" : "dogToHuman"
        
        trackTranslation(
            quality: (
                confidence: result.qualityScore.confidence,
                estimatedAccuracy: result.qualityScore.estimatedAccuracy,
                modelVersion: result.modelVersion
            ),
            latencyMs: latencyMs,
            success: true,
            translationType: translationType,
            languageDirection: languageDir
        )
    }
    
    // MARK: - Integration with RealTranslationController
    
    func trackRealTimeTranslation(
        result: AITranslationResult,
        latencyMs: Double,
        direction: TranslationDirection = .humanToDog
    ) {
        trackAITranslation(result: result, latencyMs: latencyMs, translationType: .realTime, direction: direction)
    }
    
    func trackStreamingTranslation(
        result: AITranslationResult,
        latencyMs: Double,
        direction: TranslationDirection = .humanToDog
    ) {
        trackAITranslation(result: result, latencyMs: latencyMs, translationType: .streaming, direction: direction)
    }
    
    // MARK: - Integration with LanguageRoutingService
    
    func trackLanguageChange(from: String, to: String) {
        guard let sessionId = currentSessionId else { return }
        
        let event = TranslationAnalyticsEvent(
            eventType: .languageChanged,
            sessionId: sessionId,
            metadata: ["from": from, "to": to]
        )
        eventStore.recordEvent(event)
    }
    
    // MARK: - Dashboard
    
    func getDashboardSummary() -> AnalyticsDashboardSummary {
        return aggregator.getDashboardSummary()
    }
    
    func getRealtimeMetrics() -> RealtimeMetrics {
        return aggregator.getRealtimeMetrics()
    }
    
    // MARK: - Reports
    
    func generateReport(format: ReportFormat, period: ReportPeriod = .daily) throws -> Data {
        return try reportGenerator.generateReport(format: format, period: period)
    }
    
    func generateReportURL(format: ReportFormat, period: ReportPeriod = .daily) throws -> URL {
        return try reportGenerator.generateReportURL(format: format, period: period)
    }
    
    // MARK: - Cleanup
    
    func cleanupOldData() {
        eventStore.cleanupOldEvents()
    }
    
    func clearAllData() {
        eventStore.clearAllEvents()
        qualityCollector.clearMetrics()
        usageTracker.clearUsageData()
        performanceMonitor.clearMetrics()
    }
}
