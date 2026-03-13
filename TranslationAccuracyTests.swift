import XCTest
@testable import WoofTalk

final class TranslationAccuracyTests: XCTestCase {
    
    func testBasicTranslationAccuracy() throws {
        let engine = TranslationEngine.shared
        
        // Test common phrases
        let testCases = [
            (input: "Hello", expected: "Woof"),
            (input: "Sit", expected: "Woof woof"),
            (input: "Good boy", expected: "Woof woof woof"),
            (input: "Come here", expected: "Woof woof"),
            (input: "Stay", expected: "Woof")
        ]
        
        var accuracyCount = 0
        for testCase in testCases {
            let result = engine.translateHumanToDog(testCase.input)
            if result.contains(testCase.expected) {
                accuracyCount += 1
            }
        }
        
        let accuracy = Double(accuracyCount) / Double(testCases.count)
        XCTAssertTrue(accuracy > 0.70, "Translation accuracy should be >70%, got \(accuracy * 100)%")
    }
    
    func testVocabularyCoverage() throws {
        let engine = TranslationEngine.shared
        let vocabulary = engine.getVocabularyCoverage()
        
        // Should have reasonable coverage of common phrases
        XCTAssertTrue(vocabulary.commonPhrases > 50, "Should have >50 common phrases, got \(vocabulary.commonPhrases)")
        XCTAssertTrue(vocabulary.totalPhrases > 100, "Should have >100 total phrases, got \(vocabulary.totalPhrases)")
    }
    
    func testEmptyInputHandling() throws {
        let engine = TranslationEngine.shared
        let result = engine.translateHumanToDog("")
        XCTAssertEqual(result, "", "Empty input should return empty string")
    }
    
    func testPunctuationHandling() throws {
        let engine = TranslationEngine.shared
        let result = engine.translateHumanToDog("Hello, how are you?")
        XCTAssertFalse(result.isEmpty, "Should handle punctuation and return translation")
    }
    
    func testMultipleWords() throws {
        let engine = TranslationEngine.shared
        let result = engine.translateHumanToDog("Sit down please")
        XCTAssertFalse(result.isEmpty, "Should handle multiple words")
    }
    
    func testTranslationSpeed() throws {
        let engine = TranslationEngine.shared
        let startTime = Date()
        
        for _ in 0..<100 {
            _ = engine.translateHumanToDog("Test phrase")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let avgTime = duration / 100
        XCTAssertLessThan(avgTime, 0.02, "Average translation time should be <20ms, got \(avgTime * 1000)ms")
    }
}