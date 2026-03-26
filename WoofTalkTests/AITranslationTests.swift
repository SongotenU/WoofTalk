import XCTest
@testable import WoofTalk

final class AITranslationTests: XCTestCase {
    
    var aiService: AITranslationService!
    
    override func setUp() {
        super.setUp()
        aiService = AITranslationService()
    }
    
    override func tearDown() {
        aiService = nil
        super.tearDown()
    }
    
    func testLoadModel() async throws {
        try await aiService.loadModel()
        XCTAssertTrue(aiService.isModelLoaded, "Model should be loaded")
        XCTAssertTrue(aiService.isModelAvailable, "Model should be available")
    }
    
    func testTranslateDogToHuman() async throws {
        try await aiService.loadModel()
        
        let result = try await aiService.translate(input: "woof woof", direction: .dogToHuman)
        
        XCTAssertFalse(result.translatedText.isEmpty, "Translation should not be empty")
        XCTAssertNotNil(result.qualityScore, "Quality score should be present")
        XCTAssertGreaterThan(result.qualityScore.confidence, 0.0, "Confidence should be positive")
    }
    
    func testTranslateHumanToDog() async throws {
        try await aiService.loadModel()
        
        let result = try await aiService.translate(input: "hello", direction: .humanToDog)
        
        XCTAssertFalse(result.translatedText.isEmpty, "Translation should not be empty")
    }
    
    func testFallbackTranslation() {
        let fallback = aiService.fallbackTranslate(input: "test", direction: .dogToHuman)
        XCTAssertFalse(fallback.isEmpty, "Fallback should return a translation")
    }
    
    func testQualityScoreTiers() {
        let highScore = TranslationQualityScore(confidence: 0.9, estimatedAccuracy: 0.85)
        XCTAssertEqual(highScore.qualityTier, .high)
        
        let mediumScore = TranslationQualityScore(confidence: 0.7, estimatedAccuracy: 0.65)
        XCTAssertEqual(mediumScore.qualityTier, .medium)
        
        let lowScore = TranslationQualityScore(confidence: 0.5, estimatedAccuracy: 0.45)
        XCTAssertEqual(lowScore.qualityTier, .low)
        
        let veryLowScore = TranslationQualityScore(confidence: 0.3, estimatedAccuracy: 0.25)
        XCTAssertEqual(veryLowScore.qualityTier, .veryLow)
    }
    
    func testIsConfidentThreshold() {
        let confidentResult = AITranslationResult(
            translatedText: "Hello!",
            qualityScore: TranslationQualityScore(confidence: 0.6, estimatedAccuracy: 0.55),
            inferenceTime: 0.1,
            modelVersion: "1.0.0"
        )
        XCTAssertTrue(confidentResult.isConfident, "Result with 0.6 confidence should be confident")
        
        let unconfidentResult = AITranslationResult(
            translatedText: "Hello!",
            qualityScore: TranslationQualityScore(confidence: 0.4, estimatedAccuracy: 0.35),
            inferenceTime: 0.1,
            modelVersion: "1.0.0"
        )
        XCTAssertFalse(unconfidentResult.isConfident, "Result with 0.4 confidence should not be confident")
    }
    
    func testModelVersion() {
        XCTAssertEqual(aiService.modelVersion, "1.0.0", "Model version should be 1.0.0")
    }
}