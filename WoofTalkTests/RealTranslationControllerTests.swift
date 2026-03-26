import XCTest
@testable import WoofTalk

// MARK: - Mock AI Service

final class MockAITranslationService: AITranslationServiceProtocol {
    var isModelLoaded = false
    var isModelAvailable: Bool { isModelLoaded }
    var shouldThrowOnTranslate = false
    
    func loadModel() async throws {
        isModelLoaded = true
    }
    
    var modelVersion = "1.0.0"
    
    func translate(input: String, direction: TranslationDirection) async throws -> AITranslationResult {
        if shouldThrowOnTranslate {
            throw NSError(domain: "mock", code: 1, userInfo: nil)
        }
        return AITranslationResult(
            translatedText: "AI Translation",
            qualityScore: TranslationQualityScore(confidence: 0.9, estimatedAccuracy: 0.85),
            inferenceTime: 0.1,
            modelVersion: modelVersion
        )
    }
    
    func fallbackTranslate(input: String, direction: TranslationDirection) -> String {
        return "Fallback Translation"
    }
}

// MARK: - Mock Dependencies (for other components)

final class MockAudioCapture: AudioCapture {
    override init() { super.init() }
}

final class MockSpeechRecognition: SpeechRecognition {
    override init() { super.init() }
}

final class MockAudioPlayback: AudioPlayback {
    override init() { super.init() }
}

final class MockAudioTranslationBridge: AudioTranslationBridge {
    override init() { super.init() }
}

// MARK: - Test Delegate

final class TestDelegate: NSObject, RealTranslationControllerDelegate {
    var didTranslateWithMode: (String, String, TranslationMode, TranslationQualityScore?)?
    var didTranslateBasic: (String, String)?
    var didFail: Error?
    var didUpdateMetrics: RealTranslationController.TranslationMetrics?
    
    func realTranslationControllerDidStart(_ controller: RealTranslationController) {}
    
    func realTranslationControllerDidStop(_ controller: RealTranslationController, totalTime: TimeInterval) {}
    
    func realTranslationControllerDidPause(_ controller: RealTranslationController) {}
    
    func realTranslationControllerDidResume(_ controller: RealTranslationController) {}
    
    func realTranslationController(_ controller: RealTranslationController, didUpdateMetrics metrics: RealTranslationController.TranslationMetrics) {
        didUpdateMetrics = metrics
    }
    
    func realTranslationController(_ controller: RealTranslationController, didTransitionFrom oldState: RealTranslationController.TranslationState, to newState: RealTranslationController.TranslationState) {}
    
    func realTranslationController(_ controller: RealTranslationController, didTranslate text: String, toDogTranslation: String) {
        didTranslateBasic = (text, toDogTranslation)
    }
    
    func realTranslationController(_ controller: RealTranslationController, didTranslate text: String, toDogTranslation: String, mode: TranslationMode, qualityScore: TranslationQualityScore?) {
        didTranslateWithMode = (text, toDogTranslation, mode, qualityScore)
    }
    
    func realTranslationController(_ controller: RealTranslationController, didTranslatePartial text: String, toPartialTranslation: String) {}
    
    func realTranslationController(_ controller: RealTranslationController, didRecognizePartialSpeech text: String) {}
    
    func realTranslationController(_ controller: RealTranslationController, didFailWithError error: Error) {
        didFail = error
    }
    
    func realTranslationController(_ controller: RealTranslationController, didPlayAudio duration: TimeInterval) {}
    
    func realTranslationController(_ controller: RealTranslationController, didUpdateAudioLevel level: Float) {}
}

// MARK: - Tests

final class RealTranslationControllerTests: XCTestCase {
    
    var controller: RealTranslationController!
    var mockEngine: TranslationEngine!
    var mockAudioCapture: MockAudioCapture!
    var mockSpeechRecognition: MockSpeechRecognition!
    var mockAudioPlayback: MockAudioPlayback!
    var mockTranslationBridge: MockAudioTranslationBridge!
    var mockAIService: MockAITranslationService!
    var modeManager: TranslationModeManager!
    
    override func setUp() {
        super.setUp()
        mockEngine = TranslationEngine()
        mockAudioCapture = MockAudioCapture()
        mockSpeechRecognition = MockSpeechRecognition()
        mockAudioPlayback = MockAudioPlayback()
        mockTranslationBridge = MockAudioTranslationBridge()
        mockAIService = MockAITranslationService()
        modeManager = TranslationModeManager(aiService: mockAIService)
        
        controller = RealTranslationController(
            translationEngine: mockEngine,
            audioCapture: mockAudioCapture,
            speechRecognition: mockSpeechRecognition,
            audioPlayback: mockAudioPlayback,
            translationBridge: mockTranslationBridge,
            modeManager: modeManager,
            aiService: mockAIService
        )
    }
    
    override func tearDown() {
        controller = nil
        mockEngine = nil
        mockAudioCapture = nil
        mockSpeechRecognition = nil
        mockAudioPlayback = nil
        mockTranslationBridge = nil
        mockAIService = nil
        modeManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(controller.isContinuousModeEnabled())
        XCTAssertEqual(controller.getLatencyThreshold(), 1.0)
        let metrics = controller.performanceMetrics
        XCTAssertEqual(metrics.totalTranslations, 0)
        XCTAssertEqual(metrics.failedTranslations, 0)
        XCTAssertEqual(metrics.lastTranslationLatency, 0)
    }
    
    func testStreamingDisabled() {
        controller.setStreamingEnabled(false)
        controller.setChunkSize(50)
        controller.processStreamingText("Hello world this is a test")
        XCTAssertEqual(controller.performanceMetrics.streamingChunks, 0)
    }
    
    func testStreamingEnabledAndChunkProcessing() {
        controller.setStreamingEnabled(true)
        controller.setChunkSize(50)
        let text = String(repeating: "a", count: 60)
        controller.processStreamingText(text)
        XCTAssertEqual(controller.performanceMetrics.streamingChunks, 1)
    }
    
    func testContinuousModeToggle() {
        controller.setContinuousMode(true)
        XCTAssertTrue(controller.isContinuousModeEnabled())
        controller.setContinuousMode(false)
        XCTAssertFalse(controller.isContinuousModeEnabled())
    }
    
    func testLatencyThreshold() {
        controller.setLatencyThreshold(2.5)
        XCTAssertEqual(controller.getLatencyThreshold(), 2.5)
        controller.setLatencyThreshold(0.5)
        XCTAssertEqual(controller.getLatencyThreshold(), 0.5)
    }
    
    func testTranslationWithAIModeCallsDelegateWithMode() async {
        let testDelegate = TestDelegate()
        controller.delegate = testDelegate
        
        // Enable AI mode
        await modeManager.enableAIMode()
        XCTAssertEqual(modeManager.currentMode, .ai)
        
        // Simulate speech recognition completion
        controller.speechRecognition(mockSpeechRecognition, didCompleteFinalRecognition: "hello")
        
        // Wait for async translation to complete
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertNotNil(testDelegate.didTranslateWithMode)
        let (text, translation, mode, score) = testDelegate.didTranslateWithMode!
        XCTAssertEqual(text, "hello")
        XCTAssertEqual(translation, "AI Translation")
        XCTAssertEqual(mode, .ai)
        XCTAssertEqual(score?.confidence, 0.9)
    }
    
    func testTranslationWithRuleBasedModeCallsDelegateWithRuleBased() async {
        let testDelegate = TestDelegate()
        controller.delegate = testDelegate
        
        // Default mode should be rule-based
        XCTAssertEqual(modeManager.currentMode, .ruleBased)
        
        controller.speechRecognition(mockSpeechRecognition, didCompleteFinalRecognition: "test input")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Should have received basic and detailed callbacks with rule-based
        XCTAssertNotNil(testDelegate.didTranslateBasic)
        let (text, translation) = testDelegate.didTranslateBasic!
        XCTAssertEqual(text, "test input")
        XCTAssertEqual(translation, "Fallback Translation")
        
        XCTAssertNotNil(testDelegate.didTranslateWithMode)
        let (text2, translation2, mode, score) = testDelegate.didTranslateWithMode!
        XCTAssertEqual(mode, .ruleBased)
        XCTAssertNil(score)
    }
    
    func testFallbackWhenAIThrowsCallsRuleBased() async {
        let testDelegate = TestDelegate()
        controller.delegate = testDelegate
        
        // Configure mock AI to throw when translating
        mockAIService.shouldThrowOnTranslate = true
        
        // Enable AI mode
        await modeManager.enableAIMode()
        XCTAssertEqual(modeManager.currentMode, .ai)
        
        // Simulate speech recognition completion
        controller.speechRecognition(mockSpeechRecognition, didCompleteFinalRecognition: "test input")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Should fall back to rule-based translation
        XCTAssertNotNil(testDelegate.didTranslateBasic)
        let (text, translation) = testDelegate.didTranslateBasic!
        XCTAssertEqual(text, "test input")
        XCTAssertEqual(translation, "Fallback Translation")
        
        XCTAssertNotNil(testDelegate.didTranslateWithMode)
        let (_, _, mode, score) = testDelegate.didTranslateWithMode!
        XCTAssertEqual(mode, .ruleBased)
        XCTAssertNil(score)
    }
}
