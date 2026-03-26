import XCTest
@testable import WoofTalk

final class TranslationModeSwitchTests: XCTestCase {
    
    var modeManager: TranslationModeManager!
    var mockAIService: MockAITranslationService!
    
    override func setUp() {
        super.setUp()
        mockAIService = MockAITranslationService()
        modeManager = TranslationModeManager(aiService: mockAIService)
    }
    
    override func tearDown() {
        modeManager = nil
        mockAIService = nil
        super.tearDown()
    }
    
    func testInitialModeIsRuleBased() {
        XCTAssertEqual(modeManager.currentMode, .ruleBased, "Initial mode should be rule-based")
    }
    
    func testEnableAIMode() async {
        await modeManager.enableAIMode()
        
        XCTAssertEqual(modeManager.currentMode, .ai, "Mode should be AI after enabling")
        XCTAssertTrue(modeManager.isAIReady, "AI should be ready")
    }
    
    func testEnableRuleBasedMode() async {
        await modeManager.enableAIMode()
        modeManager.enableRuleBasedMode()
        
        XCTAssertEqual(modeManager.currentMode, .ruleBased, "Mode should be rule-based after disabling")
    }
    
    func testToggleMode() async {
        XCTAssertEqual(modeManager.currentMode, .ruleBased)
        
        await modeManager.toggleMode()
        XCTAssertEqual(modeManager.currentMode, .ai)
        
        await modeManager.toggleMode()
        XCTAssertEqual(modeManager.currentMode, .ruleBased)
    }
    
    func testFallbackOnError() async {
        mockAIService.shouldFailLoad = true
        
        await modeManager.enableAIMode()
        
        XCTAssertEqual(modeManager.currentMode, .ruleBased, "Should fall back to rule-based on error")
        XCTAssertNotNil(modeManager.lastError, "Error should be recorded")
    }
}

class MockAITranslationService: AITranslationServiceProtocol {
    var isModelLoaded = false
    var shouldFailLoad = false
    
    var isModelAvailable: Bool { isModelLoaded }
    
    func loadModel() async throws {
        if shouldFailLoad {
            throw AITranslationError.modelLoadFailed("Mock failure")
        }
        isModelLoaded = true
    }
    
    var modelVersion: String { "1.0.0" }
    
    func translate(input: String, direction: TranslationDirection) async throws -> AITranslationResult {
        return AITranslationResult(
            translatedText: "Test translation",
            qualityScore: TranslationQualityScore(confidence: 0.8, estimatedAccuracy: 0.75),
            inferenceTime: 0.1,
            modelVersion: "1.0.0"
        )
    }
    
    func fallbackTranslate(input: String, direction: TranslationDirection) -> String {
        return "Fallback translation"
    }
}