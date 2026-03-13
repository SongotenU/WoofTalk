import XCTest
@testable import WoofTalk

final class IntegrationTests: XCTestCase {
    
    func testEndToEndTranslation() throws {
        let engine = TranslationEngine.shared
        
        // Test complete translation pipeline
        let humanPhrases = [
            "Hello",
            "Sit down",
            "Good boy",
            "Come here please",
            "Stay quiet",
            "Go fetch",
            "Roll over",
            "Shake hands",
            "Speak",
            "Quiet"
        ]
        
        for phrase in humanPhrases {
            let dogTranslation = engine.translateHumanToDog(phrase)
            XCTAssertFalse(dogTranslation.isEmpty, "Translation should not be empty for phrase: \(phrase)")
            
            // Test reverse translation
            let humanTranslation = engine.translateDogToHuman(dogTranslation)
            XCTAssertFalse(humanTranslation.isEmpty, "Reverse translation should not be empty")
            
            // Should be able to translate back and forth
            XCTAssertNotEqual(humanTranslation, phrase, "Reverse translation should not be identical to original")
        }
    }
    
    func testTranslationConsistency() throws {
        let engine = TranslationEngine.shared
        let testPhrase = "Good boy"
        
        // Test consistency across multiple calls
        let firstResult = engine.translateHumanToDog(testPhrase)
        let secondResult = engine.translateHumanToDog(testPhrase)
        let thirdResult = engine.translateHumanToDog(testPhrase)
        
        XCTAssertEqual(firstResult, secondResult, "Translation should be consistent across calls")
        XCTAssertEqual(secondResult, thirdResult, "Translation should be consistent across calls")
    }
    
    func testErrorHandling() throws {
        let engine = TranslationEngine.shared
        
        // Test error handling for various scenarios
        let errorCases = [
            (input: "", expectedError: TranslationError.emptyInput),
            (input: String(repeating: "a", count: 10000), expectedError: TranslationError.inputTooLong)
        ]
        
        for errorCase in errorCases {
            do {
                _ = try engine.translateHumanToDog(errorCase.input)
                XCTFail("Expected error for input: \(errorCase.input)")
            } catch let error as TranslationError {
                XCTAssertEqual(error, errorCase.expectedError, "Expected \(errorCase.expectedError), got \(error)")
            } catch {
                XCTFail("Expected TranslationError, got \(error)")
            }
        }
    }
    
    func testRealWorldScenarios() throws {
        let engine = TranslationEngine.shared
        
        // Test common real-world scenarios
        let scenarios = [
            (input: "I need to go outside", expected: "Woof woof woof"),
            (input: "Are you hungry?", expected: "Woof woof"),
            (input: "Let's go for a walk", expected: "Woof woof woof woof"),
            (input: "Don't touch that", expected: "Woof woof")
        ]
        
        for scenario in scenarios {
            let result = engine.translateHumanToDog(scenario.input)
            XCTAssertFalse(result.isEmpty, "Should handle real-world scenario: \(scenario.input)")
        }
    }
    
    func testTranslationWithSpecialCharacters() throws {
        let engine = TranslationEngine.shared
        let testCases = [
            "Hello! How are you?",
            "Sit down, please.",
            "Good boy!!!",
            "Come here...",
            "What's up?",
            "It's a beautiful day!"
        ]
        
        for testCase in testCases {
            let result = engine.translateHumanToDog(testCase)
            XCTAssertFalse(result.isEmpty, "Should handle special characters in: \(testCase)")
        }
    }
}