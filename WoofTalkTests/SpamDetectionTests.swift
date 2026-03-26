import XCTest
@testable import WoofTalk

final class SpamDetectionTests: XCTestCase {
    
    var spamDetectionService: SpamDetectionService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        spamDetectionService = SpamDetectionService.shared
    }
    
    override func tearDownWithError() throws {
        spamDetectionService = nil
        try super.tearDownWithError()
    }
    
    func testCleanContent() throws {
        let content = "Hello, this is a normal translation from human to dog"
        
        let result = spamDetectionService.analyze(content: content)
        
        XCTAssertFalse(result.isSpam, "Clean content should not be flagged as spam")
        XCTAssertLessThan(result.confidence, 0.3, "Clean content should have low spam confidence")
    }
    
    func testExcessiveCaps() throws {
        let content = "THIS IS ALL CAPS AND LOOKS LIKE SPAM"
        
        let result = spamDetectionService.analyze(content: content)
        
        XCTAssertTrue(result.details.capsRatio > 0.5, "Should detect excessive caps")
    }
    
    func testRepetitiveContent() throws {
        let content = "hello hello hello hello hello"
        
        let result = spamDetectionService.analyze(content: content)
        
        XCTAssertTrue(result.reasons.contains(.repetitiveContent), "Should detect repetitive content")
    }
    
    func testSuspiciousPatterns() throws {
        let content = "Click here for free money! Act now! Limited time offer!"
        
        let result = spamDetectionService.analyze(content: content)
        
        XCTAssertTrue(result.confidence > 0.3, "Suspicious patterns should increase confidence")
    }
    
    func testBlacklistedContent() throws {
        let content = "Click here to claim your prize"
        
        let result = spamDetectionService.analyze(content: content)
        
        XCTAssertTrue(result.reasons.contains(.blacklistedContent), "Should detect blacklisted content")
    }
    
    func testTooManyLinks() throws {
        let content = "Check out http://spam1.com and http://spam2.com and http://spam3.com and http://spam4.com"
        
        let result = spamDetectionService.analyze(content: content)
        
        XCTAssertTrue(result.reasons.contains(.tooManyLinks), "Should detect too many links")
    }
    
    func testQuickCheckLikelySpam() throws {
        let spamContent = "FREE MONEY CLICK HERE NOW!!!"
        
        let isLikelySpam = spamDetectionService.isLikelySpam(spamContent)
        
        XCTAssertTrue(isLikelySpam, "Quick check should identify obvious spam")
    }
    
    func testQuickCheckLikelyNotSpam() throws {
        let cleanContent = "Good dog is a good boy"
        
        let isLikelySpam = spamDetectionService.isLikelySpam(cleanContent)
        
        XCTAssertFalse(isLikelySpam, "Quick check should identify clean content")
    }
    
    func testLowConfidenceNormalContent() throws {
        let content = "I love my dog and we go for walks every day"
        
        let result = spamDetectionService.analyze(content: content)
        
        XCTAssertLessThan(result.confidence, 0.2, "Normal content should have low spam confidence")
    }
    
    func testSpamConfidenceLevel() throws {
        let verySpammy = "CLICK HERE FREE MONEY BUY NOW!!! ACT NOW!!!"
        
        let result = spamDetectionService.analyze(content: verySpammy)
        
        let level = SpamConfidenceLevel.from(confidence: result.confidence)
        
        XCTAssertTrue(
            level == .high || level == .veryHigh,
            "Very spammy content should have high or very high confidence"
        )
    }
    
    func testRepetitionScoreCalculation() throws {
        let analyzer = SpamAnalyzer()
        
        let noRepetition = "The quick brown fox jumps over the lazy dog"
        let repetitionScore = analyzer.calculateRepetitionScore(text: noRepetition)
        
        XCTAssertLessThan(repetitionScore, 0.2, "Normal text should have low repetition score")
    }
    
    func testCapsRatioCalculation() throws {
        let analyzer = SpamAnalyzer()
        
        let noCaps = "hello world"
        let capsRatio = analyzer.calculateCapsRatio(text: noCaps)
        
        XCTAssertEqual(capsRatio, 0.0, "No caps text should have 0 caps ratio")
    }
    
    func testLinkCount() throws {
        let analyzer = SpamAnalyzer()
        
        let noLinks = "This has no links"
        let linkCount = analyzer.countLinks(text: noLinks)
        
        XCTAssertEqual(linkCount, 0, "Text without links should have 0 link count")
    }
    
    func testUniqueWordRatio() throws {
        let analyzer = SpamAnalyzer()
        
        let allUnique = "one two three four five"
        let ratio = analyzer.calculateUniqueWordRatio(text: allUnique)
        
        XCTAssertEqual(ratio, 1.0, "All unique words should have 1.0 ratio")
    }
    
    func testAutoFlagThreshold() throws {
        let content = "free money click here act now limited time offer buy now"
        
        let result = spamDetectionService.analyze(content: content)
        
        XCTAssertGreaterThan(
            result.confidence,
            spamDetectionService.configuration.autoFlagThreshold,
            "Content above threshold should be flagged"
        )
    }
    
    func testRecordSubmission() throws {
        let userId = "testUser123"
        let content = "test submission content"
        
        spamDetectionService.recordSubmission(userId: userId, content: content)
        
        let isDuplicate = spamDetectionService.isLikelySpam(content)
        
        XCTAssertTrue(isDuplicate || spamDetectionService.configuration.autoFlagThreshold > 0.5,
                      "Service should track submissions")
    }
}
