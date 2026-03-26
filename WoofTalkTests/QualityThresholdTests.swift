import XCTest
@testable import WoofTalk

final class QualityThresholdTests: XCTestCase {
    
    var policy: QualityThresholdPolicy!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        policy = QualityThresholdPolicy.shared
    }
    
    override func tearDownWithError() throws {
        policy.resetToDefaults()
        policy = nil
        try super.tearDownWithError()
    }
    
    func testDefaultThresholdsExist() throws {
        let thresholds = policy.getThresholds()
        
        XCTAssertFalse(thresholds.isEmpty, "Should have default thresholds")
    }
    
    func testHighQualityAutoApprove() throws {
        let contribution = createMockContribution(qualityScore: 0.9)
        
        let result = policy.evaluate(contribution: contribution)
        
        XCTAssertEqual(result.action, .autoApprove)
        XCTAssertEqual(result.reason, "High quality content")
    }
    
    func testLowQualityAutoReject() throws {
        let contribution = createMockContribution(qualityScore: 0.2)
        
        let result = policy.evaluate(contribution: contribution)
        
        XCTAssertEqual(result.action, .autoReject)
        XCTAssertEqual(result.reason, "Low quality content")
    }
    
    func testMediumQualityManualReview() throws {
        let contribution = createMockContribution(qualityScore: 0.7)
        
        let result = policy.evaluate(contribution: contribution)
        
        XCTAssertEqual(result.action, .manualReview)
    }
    
    func testBorderlineQualityManualReview() throws {
        let contribution = createMockContribution(qualityScore: 0.4)
        
        let result = policy.evaluate(contribution: contribution)
        
        XCTAssertEqual(result.action, .manualReview)
    }
    
    func testQualityScoreAtBoundary() throws {
        let highThreshold = createMockContribution(qualityScore: 0.85)
        let resultHigh = policy.evaluate(contribution: highThreshold)
        
        XCTAssertEqual(resultHigh.action, .autoApprove, "Score at 0.85 should auto-approve")
        
        let mediumThreshold = createMockContribution(qualityScore: 0.84)
        let resultMedium = policy.evaluate(contribution: mediumThreshold)
        
        XCTAssertEqual(resultMedium.action, .manualReview, "Score at 0.84 should require review")
    }
    
    func testAddCustomThreshold() throws {
        let customThreshold = QualityThreshold(
            minQualityScore: 0.6,
            maxQualityScore: 0.7,
            action: .autoApprove,
            reason: "Custom mid-range approval"
        )
        
        policy.addThreshold(customThreshold)
        
        let contribution = createMockContribution(qualityScore: 0.65)
        let result = policy.evaluate(contribution: contribution)
        
        XCTAssertEqual(result.action, .autoApprove)
        XCTAssertEqual(result.reason, "Custom mid-range approval")
    }
    
    func testRemoveThreshold() throws {
        let initialCount = policy.getThresholds().count
        
        policy.removeThreshold(at: 0)
        
        let afterCount = policy.getThresholds().count
        XCTAssertLessThan(afterCount, initialCount)
    }
    
    func testThresholdPriorityOrder() throws {
        policy.resetToDefaults()
        
        let customThreshold = QualityThreshold(
            minQualityScore: 0.95,
            maxQualityScore: 1.0,
            action: .autoApprove,
            reason: "Premium quality"
        )
        
        policy.addThreshold(customThreshold)
        
        let thresholds = policy.getThresholds()
        
        XCTAssertEqual(thresholds.first?.minQualityScore, 0.95, "Highest quality threshold should be first")
    }
    
    func testEvaluateWithNoMatchingThreshold() throws {
        let contribution = createMockContribution(qualityScore: 1.5)
        
        let result = policy.evaluate(contribution: contribution)
        
        XCTAssertEqual(result.action, .manualReview, "Out of range should default to manual review")
    }
    
    func testConfidenceCalculation() throws {
        let contribution = createMockContribution(qualityScore: 0.9)
        
        let result = policy.evaluate(contribution: contribution)
        
        XCTAssertGreaterThan(result.confidence, 0.0, "Should calculate confidence")
    }
    
    func testResetToDefaults() throws {
        let customThreshold = QualityThreshold(
            minQualityScore: 0.5,
            maxQualityScore: 0.6,
            action: .autoApprove,
            reason: "Custom"
        )
        
        policy.addThreshold(customThreshold)
        policy.resetToDefaults()
        
        let contribution = createMockContribution(qualityScore: 0.55)
        let result = policy.evaluate(contribution: contribution)
        
        XCTAssertNotEqual(result.reason, "Custom", "Should reset to default thresholds")
    }
    
    func testModerationActionDescriptions() throws {
        XCTAssertEqual(ModerationAction.autoApprove.rawValue, "auto_approve")
        XCTAssertEqual(ModerationAction.autoReject.rawValue, "auto_reject")
        XCTAssertEqual(ModerationAction.manualReview.rawValue, "manual_review")
        XCTAssertEqual(ModerationAction.escalate.rawValue, "escalate")
    }
    
    func testPolicyEvaluationResult() throws {
        let result = PolicyEvaluationResult(
            action: .autoApprove,
            reason: "Test reason",
            qualityScore: 0.9,
            confidence: 0.8
        )
        
        XCTAssertFalse(result.requiresManualReview)
        
        let reviewResult = PolicyEvaluationResult(
            action: .manualReview,
            reason: "Review needed",
            qualityScore: 0.5,
            confidence: 0.3
        )
        
        XCTAssertTrue(reviewResult.requiresManualReview)
        
        let escalateResult = PolicyEvaluationResult(
            action: .escalate,
            reason: "Escalated",
            qualityScore: 0.4,
            confidence: 0.6
        )
        
        XCTAssertTrue(escalateResult.requiresManualReview)
    }
    
    func testQualityThresholdEvaluate() throws {
        let threshold = QualityThreshold(
            minQualityScore: 0.5,
            maxQualityScore: 0.8,
            action: .autoApprove,
            reason: "Test"
        )
        
        XCTAssertTrue(threshold.evaluate(qualityScore: 0.6))
        XCTAssertTrue(threshold.evaluate(qualityScore: 0.5))
        XCTAssertTrue(threshold.evaluate(qualityScore: 0.8))
        XCTAssertFalse(threshold.evaluate(qualityScore: 0.4))
        XCTAssertFalse(threshold.evaluate(qualityScore: 0.9))
    }
    
    private func createMockContribution(qualityScore: Double) -> Contribution {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        let contribution = Contribution(context: context)
        contribution.qualityScore = qualityScore
        contribution.humanText = "Test text"
        contribution.dogTranslation = "Test translation"
        
        return contribution
    }
}
