import XCTest
@testable import WoofTalk

final class RealTimeTranslationTests: XCTestCase {
    
    var controller: RealTranslationController!
    var mockAudioCapture: MockAudioCapture!
    var mockSpeechRecognition: MockSpeechRecognition!
    var mockAudioPlayback: MockAudioPlayback!
    var mockTranslationBridge: MockTranslationBridge!
    
    override func setUp() {
        super.setUp()
        
        mockAudioCapture = MockAudioCapture()
        mockSpeechRecognition = MockSpeechRecognition()
        mockAudioPlayback = MockAudioPlayback()
        mockTranslationBridge = MockTranslationBridge()
        
        let translationEngine = TranslationEngine()
        
        controller = RealTranslationController(
            translationEngine: translationEngine,
            audioCapture: mockAudioCapture,
            speechRecognition: mockSpeechRecognition,
            audioPlayback: mockAudioPlayback,
            translationBridge: mockTranslationBridge
        )
    }
    
    override func tearDown() {
        controller = nil
        mockAudioCapture = nil
        mockSpeechRecognition = nil
        mockAudioPlayback = nil
        mockTranslationBridge = nil
        
        super.tearDown()
    }
    
    func testStreamingEnabled() {
        controller.setStreamingEnabled(true)
        
        controller.setChunkSize(50)
        controller.processStreamingText("Hello world this is a test")
        
        XCTAssertEqual(controller.performanceMetrics.streamingChunks, 1)
    }
    
    func testStreamingDisabled() {
        controller.setStreamingEnabled(false)
        
        controller.processStreamingText("Hello world")
        
        XCTAssertEqual(controller.performanceMetrics.streamingChunks, 0)
    }
    
    func testContinuousModeToggle() {
        XCTAssertFalse(controller.isContinuousModeEnabled())
        
        controller.setContinuousMode(true)
        
        XCTAssertTrue(controller.isContinuousModeEnabled())
        
        controller.setContinuousMode(false)
        
        XCTAssertFalse(controller.isContinuousModeEnabled())
    }
    
    func testLatencyThreshold() {
        controller.setLatencyThreshold(1.5)
        
        XCTAssertEqual(controller.getLatencyThreshold(), 1.5)
        
        controller.setLatencyThreshold(0.5)
        
        XCTAssertEqual(controller.getLatencyThreshold(), 0.5)
    }
    
    func testLatencyWithinThreshold() {
        let metrics = RealTranslationController.TranslationMetrics(
            lastTranslationLatency: 0.8,
            averageLatency: 0.9,
            bufferProcessingTime: 0.1,
            translationSuccessRate: 0.95,
            totalTranslations: 20,
            failedTranslations: 1,
            streamingChunks: 0,
            lastChunkLatency: 0.7
        )
        
        XCTAssertTrue(metrics.lastTranslationLatency < 1.0)
    }
    
    func testMetricsTracking() {
        let metrics = controller.performanceMetrics
        
        XCTAssertEqual(metrics.totalTranslations, 0)
        XCTAssertEqual(metrics.failedTranslations, 0)
    }
}

final class MockAudioCapture: AudioCapture {
    override init() {
        super.init()
    }
}

final class MockSpeechRecognition: SpeechRecognition {
    override init() {
        super.init()
    }
}

final class MockAudioPlayback: AudioPlayback {
    override init() {
        super.init()
    }
}

final class MockTranslationBridge: AudioTranslationBridge {
    override init() {
        super.init()
    }
}

final class LatencyMonitorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        LatencyMonitor.shared.clearHistory()
    }
    
    override func tearDown() {
        LatencyMonitor.shared.clearHistory()
        super.tearDown()
    }
    
    func testRecordLatency() {
        LatencyMonitor.shared.recordLatency(0.5, translationType: "humanToDog", success: true)
        LatencyMonitor.shared.recordLatency(0.8, translationType: "humanToDog", success: true)
        LatencyMonitor.shared.recordLatency(1.2, translationType: "humanToDog", success: false)
        
        let avg = LatencyMonitor.shared.getAverageLatency()
        
        XCTAssertEqual(avg, 0.83, accuracy: 0.01)
    }
    
    func testSuccessRate() {
        LatencyMonitor.shared.recordLatency(0.5, translationType: "humanToDog", success: true)
        LatencyMonitor.shared.recordLatency(0.8, translationType: "humanToDog", success: true)
        LatencyMonitor.shared.recordLatency(1.2, translationType: "humanToDog", success: false)
        
        let rate = LatencyMonitor.shared.getSuccessRate()
        
        XCTAssertEqual(rate, 0.666, accuracy: 0.01)
    }
    
    func testP50Latency() {
        for i in 1...100 {
            LatencyMonitor.shared.recordLatency(Double(i) / 100.0, translationType: "test", success: true)
        }
        
        let p50 = LatencyMonitor.shared.getP50Latency()
        
        XCTAssertEqual(p50, 0.5, accuracy: 0.05)
    }
    
    func testP95Latency() {
        for i in 1...100 {
            LatencyMonitor.shared.recordLatency(Double(i) / 100.0, translationType: "test", success: true)
        }
        
        let p95 = LatencyMonitor.shared.getP95Latency()
        
        XCTAssertEqual(p95, 0.95, accuracy: 0.05)
    }
    
    func testLatencyDistribution() {
        LatencyMonitor.shared.recordLatency(0.3, translationType: "test", success: true)
        LatencyMonitor.shared.recordLatency(0.7, translationType: "test", success: true)
        LatencyMonitor.shared.recordLatency(1.5, translationType: "test", success: true)
        LatencyMonitor.shared.recordLatency(2.5, translationType: "test", success: true)
        
        let dist = LatencyMonitor.shared.getLatencyDistribution()
        
        XCTAssertEqual(dist["<500ms"], 1)
        XCTAssertEqual(dist["500ms-1s"], 1)
        XCTAssertEqual(dist["1s-2s"], 1)
        XCTAssertEqual(dist[">2s"], 1)
    }
    
    func testReportGeneration() {
        LatencyMonitor.shared.recordLatency(0.5, translationType: "humanToDog", success: true)
        LatencyMonitor.shared.recordLatency(0.8, translationType: "humanToDog", success: true)
        
        let report = LatencyMonitor.shared.getReport()
        
        XCTAssertTrue(report.meetsTarget)
        XCTAssertEqual(report.totalTranslations, 2)
    }
}
