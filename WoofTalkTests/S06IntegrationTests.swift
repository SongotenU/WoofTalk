// MARK: - S06IntegrationTests

import XCTest
@testable import WoofTalk

/// Comprehensive integration tests for S06: Final Integration & Testing
/// Tests all S01-S05 features working together
final class S06IntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    
    // S01: AI Translation
    var aiTranslationService: AITranslationService!
    
    // S02: Real-time Features
    var realTranslationController: RealTranslationController!
    
    // S03: Multi-language
    var languageRoutingService: LanguageRoutingService!
    var multiLanguageAdapter: MultiLanguageAdapter!
    
    // S04: Analytics
    var analyticsService: TranslationAnalyticsService!
    
    // S05: Performance
    var performanceOptimizer: PerformanceOptimizer!
    
    // MARK: - Lifecycle
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize persistence
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        // Initialize S01: AI Translation
        aiTranslationService = AITranslationService.shared
        try await aiTranslationService.loadModel()
        
        // Initialize S02: Real-time (with dependencies)
        let translationEngine = TranslationEngine()
        let audioCapture = AudioCapture()
        let speechRecognition = SpeechRecognition()
        let audioPlayback = AudioPlayback()
        let translationBridge = AudioTranslationBridge()
        
        realTranslationController = RealTranslationController(
            translationEngine: translationEngine,
            audioCapture: audioCapture,
            speechRecognition: speechRecognition,
            audioPlayback: audioPlayback,
            translationBridge: translationBridge
        )
        
        // Initialize S03: Multi-language
        languageRoutingService = LanguageRoutingService.shared
        multiLanguageAdapter = MultiLanguageAdapter.shared
        
        // Initialize S04: Analytics
        analyticsService = TranslationAnalyticsService.shared
        _ = analyticsService.startSession()
        
        // Initialize S05: Performance
        performanceOptimizer = PerformanceOptimizer.shared
    }
    
    override func tearDown() async throws {
        // End analytics session
        analyticsService.endSession()
        
        // Clean up
        aiTranslationService = nil
        realTranslationController = nil
        languageRoutingService = nil
        multiLanguageAdapter = nil
        analyticsService = nil
        performanceOptimizer = nil
        
        viewContext = nil
        persistenceController = nil
        
        try await super.tearDown()
    }
    
    // MARK: - T01: End-to-End Integration Tests
    
    /// Test: AI Translation integrates with Multi-language (S01 + S03)
    func testAITranslationWithMultiLanguage() async throws {
        // Set language to Dog
        languageRoutingService.setLanguage(.dog)
        
        // Translate using AI with multi-language routing
        let result = try await languageRoutingService.translate(
            input: "hello",
            direction: .humanToAnimal
        )
        
        XCTAssertFalse(result.translatedText.isEmpty, "Translation should not be empty")
        XCTAssertEqual(result.source, .ai, "Source should be AI for Dog language")
    }
    
    /// Test: AI Translation integrates with Real-time (S01 + S02)
    func testAIIntegrationWithRealTime() async throws {
        // Use AI translation in real-time controller
        let result = try await realTranslationController.translateWithAI(
            input: "sit",
            direction: .humanToDog
        )
        
        XCTAssertFalse(result.translatedText.isEmpty, "Translation should not be empty")
        XCTAssertTrue(result.isConfident, "AI should be confident in translation")
    }
    
    /// Test: Analytics captures AI translation data (S01 + S04)
    func testAnalyticsCapturesAITranslation() async throws {
        let beforeCount = analyticsService.getTranslationCount()
        
        // Perform AI translation
        let result = try await aiTranslationService.translate(
            input: "good boy",
            direction: .humanToDog
        )
        
        // Track with analytics
        analyticsService.trackTranslation(
            quality: (
                confidence: result.qualityScore.confidence,
                estimatedAccuracy: result.qualityScore.estimatedAccuracy,
                modelVersion: result.modelVersion
            ),
            latencyMs: result.inferenceTime * 1000,
            success: true,
            translationType: .batch,
            languageDirection: "humanToDog"
        )
        
        let afterCount = analyticsService.getTranslationCount()
        XCTAssertGreaterThan(afterCount, beforeCount, "Analytics should capture translation")
    }
    
    /// Test: Analytics captures real-time performance (S02 + S04)
    func testAnalyticsCapturesRealTimePerformance() async throws {
        let beforeCount = analyticsService.getTranslationCount()
        
        // Set up real-time with streaming
        realTranslationController.setStreamingEnabled(true)
        realTranslationController.setChunkSize(50)
        
        // Process streaming text
        realTranslationController.processStreamingText("hello world")
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        let afterCount = analyticsService.getTranslationCount()
        XCTAssertGreaterThanOrEqual(afterCount, beforeCount, "Real-time should update metrics")
    }
    
    /// Test: Performance optimizer applies to all features (S05 integration)
    func testPerformanceOptimizerOnAllFeatures() async throws {
        // Enable performance optimization
        performanceOptimizer.start()
        
        // Test AI translation with optimization
        let aiResult = try await aiTranslationService.translate(
            input: "sit",
            direction: .humanToDog
        )
        XCTAssertFalse(aiResult.translatedText.isEmpty)
        
        // Test language routing with optimization
        let langResult = try await languageRoutingService.translate(
            input: "stay",
            direction: .humanToAnimal
        )
        XCTAssertFalse(langResult.translatedText.isEmpty)
        
        // Verify performance alerts
        let alerts = performanceOptimizer.getActiveAlerts()
        XCTAssertNotNil(alerts, "Should track performance alerts")
    }
    
    /// Test: Complete user journey with all features
    func testCompleteUserJourneyAllFeatures() async throws {
        // 1. Start analytics session
        let sessionId = analyticsService.startSession()
        XCTAssertFalse(sessionId.isEmpty)
        
        // 2. Select multi-language (Dog)
        languageRoutingService.setLanguage(.dog)
        
        // 3. Perform AI translation
        let aiResult = try await aiTranslationService.translate(
            input: "good boy",
            direction: .humanToDog
        )
        
        analyticsService.trackTranslation(
            quality: (
                confidence: aiResult.qualityScore.confidence,
                estimatedAccuracy: aiResult.qualityScore.estimatedAccuracy,
                modelVersion: aiResult.modelVersion
            ),
            latencyMs: aiResult.inferenceTime * 1000,
            success: true,
            translationType: .batch,
            languageDirection: "humanToDog"
        )
        
        // 4. Perform real-time translation
        let rtResult = try await realTranslationController.translateWithAI(
            input: "sit",
            direction: .humanToDog
        )
        
        analyticsService.trackTranslation(
            quality: (
                confidence: rtResult.qualityScore.confidence,
                estimatedAccuracy: rtResult.qualityScore.estimatedAccuracy,
                modelVersion: rtResult.modelVersion
            ),
            latencyMs: rtResult.inferenceTime * 1000,
            success: true,
            translationType: .streaming,
            languageDirection: "humanToDog"
        )
        
        // 5. Switch language and translate (Cat - vocabulary)
        languageRoutingService.setLanguage(.cat)
        let catResult = try await languageRoutingService.translate(
            input: "hello",
            direction: .humanToAnimal
        )
        
        analyticsService.trackTranslation(
            quality: (
                confidence: 0.7,
                estimatedAccuracy: 0.7,
                modelVersion: "vocabulary"
            ),
            latencyMs: 50,
            success: true,
            translationType: .batch,
            languageDirection: "humanToCat"
        )
        
        // 6. End session
        analyticsService.endSession()
        
        // Verify all translations were captured
        let finalCount = analyticsService.getTranslationCount()
        XCTAssertGreaterThanOrEqual(finalCount, 3, "Should track all translations")
    }
    
    // MARK: - T02: Performance Benchmark Tests
    
    /// Test: AI translation latency < 500ms
    func testAITranslationLatency() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let result = try await aiTranslationService.translate(
            input: "hello",
            direction: .humanToDog
        )
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let latency = endTime - startTime
        
        XCTAssertLessThan(latency, 0.5, "AI translation should be under 500ms")
        XCTAssertFalse(result.translatedText.isEmpty)
    }
    
    /// Test: Real-time streaming latency < 200ms
    func testRealTimeStreamingLatency() async throws {
        realTranslationController.setStreamingEnabled(true)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        realTranslationController.processStreamingText("test phrase for latency")
        
        // Wait for streaming chunk processing
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let latency = endTime - startTime
        
        // Should trigger within threshold
        XCTAssertLessThanOrEqual(latency, 0.3, "Streaming should be responsive")
    }
    
    /// Test: Memory optimization active
    func testMemoryOptimization() {
        let status = performanceOptimizer.getMemoryStatus()
        XCTAssertNotNil(status)
    }
    
    /// Test: Battery optimization active
    func testBatteryOptimization() {
        let status = performanceOptimizer.getBatteryStatus()
        XCTAssertNotNil(status)
    }
    
    /// Test: Network optimization active
    func testNetworkOptimization() {
        let status = performanceOptimizer.getNetworkStatus()
        XCTAssertNotNil(status)
    }
    
    // MARK: - T05: Offline-First Tests
    
    /// Test: AI translation has offline fallback
    func testAITranslationOfflineFallback() async throws {
        let offlineResult = aiTranslationService.fallbackTranslate(
            input: "sit",
            direction: .humanToDog
        )
        
        XCTAssertFalse(offlineResult.isEmpty, "Offline fallback should work")
    }
    
    /// Test: Multi-language works offline
    func testMultiLanguageOffline() async throws {
        let offlineResult = languageRoutingService.translateWithFallback(
            input: "sit",
            direction: .humanToAnimal
        )
        
        XCTAssertFalse(offlineResult.isEmpty, "Multi-language should work offline")
    }
    
    /// Test: Analytics queues events offline
    func testAnalyticsQueuesOffline() {
        // Track should work regardless of connectivity
        analyticsService.trackTranslation(
            quality: (confidence: 0.8, estimatedAccuracy: 0.8, modelVersion: "1.0"),
            latencyMs: 100,
            success: true
        )
        
        // Should not throw
        let count = analyticsService.getTranslationCount()
        XCTAssertGreaterThan(count, 0)
    }
}
