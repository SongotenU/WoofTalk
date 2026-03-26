//
//  ContributionValidationTests.swift
//  WoofTalkTests
//
//  Created by vandopha on 3/20/26.
//

import XCTest
@testable import WoofTalk

final class ContributionValidationTests: XCTestCase {
    
    var validationService: ContributionValidationService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        validationService = ContributionValidationService()
    }
    
    override func tearDownWithError() throws {
        validationService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Validation Tests
    
    func testValidTranslation() throws {
        let translation = TranslationRecord(
            humanText: "sit",
            dogTranslation: "woof woof woof"
        )
        
        let result = validationService.validate(translationRecord: translation)
        
        switch result {
        case .valid(let qualityScore):
            XCTAssertTrue(qualityScore > 0.0, "Valid translation should have positive quality score")
            XCTAssertTrue(qualityScore <= 1.0, "Quality score should be between 0 and 1")
        case .invalid, .warning:
            XCTFail("Valid translation should return .valid result")
        }
    }
    
    func testEmptyFields() throws {
        // Both fields empty
        let emptyBoth = TranslationRecord(humanText: "", dogTranslation: "")
        let resultBoth = validationService.validate(translationRecord: emptyBoth)
        
        switch resultBoth {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.emptyField(field: "humanText")))
            XCTAssertTrue(errors.contains(.emptyField(field: "dogTranslation")))
        default:
            XCTFail("Empty fields should return .invalid result")
        }
        
        // Human text empty
        let emptyHuman = TranslationRecord(humanText: "", dogTranslation: "woof woof woof")
        let resultHuman = validationService.validate(translationRecord: emptyHuman)
        
        switch resultHuman {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.emptyField(field: "humanText")))
        default:
            XCTFail("Empty human text should return .invalid result")
        }
        
        // Dog translation empty
        let emptyDog = TranslationRecord(humanText: "sit", dogTranslation: "")
        let resultDog = validationService.validate(translationRecord: emptyDog)
        
        switch resultDog {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.emptyField(field: "dogTranslation")))
        default:
            XCTFail("Empty dog translation should return .invalid result")
        }
    }
    
    func testLengthConstraints() throws {
        // Too short human text
        let tooShortHuman = TranslationRecord(
            humanText: "a",
            dogTranslation: "woof woof woof"
        )
        let resultShortHuman = validationService.validate(translationRecord: tooShortHuman)
        
        switch resultShortHuman {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.tooShort(field: "humanText", minLength: 2, actualLength: 1)))
        default:
            XCTFail("Too short human text should return .invalid result")
        }
        
        // Too long human text
        let tooLongHuman = TranslationRecord(
            humanText: String(repeating: "a", count: 101),
            dogTranslation: "woof woof woof"
        )
        let resultLongHuman = validationService.validate(translationRecord: tooLongHuman)
        
        switch resultLongHuman {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.tooLong(field: "humanText", maxLength: 100, actualLength: 101)))
        default:
            XCTFail("Too long human text should return .invalid result")
        }
        
        // Too short dog translation
        let tooShortDog = TranslationRecord(
            humanText: "sit",
            dogTranslation: "a"
        )
        let resultShortDog = validationService.validate(translationRecord: tooShortDog)
        
        switch resultShortDog {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.tooShort(field: "dogTranslation", minLength: 2, actualLength: 1)))
        default:
            XCTFail("Too short dog translation should return .invalid result")
        }
        
        // Too long dog translation
        let tooLongDog = TranslationRecord(
            humanText: "sit",
            dogTranslation: String(repeating: "woof ", count: 26)
        )
        let resultLongDog = validationService.validate(translationRecord: tooLongDog)
        
        switch resultLongDog {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.tooLong(field: "dogTranslation", maxLength: 50, actualLength: 101)))
        default:
            XCTFail("Too long dog translation should return .invalid result")
        }
    }
    
    func testProfanityDetection() throws {
        // Profanity in human text
        let profaneHuman = TranslationRecord(
            humanText: "badword1",
            dogTranslation: "woof woof woof"
        )
        let resultHuman = validationService.validate(translationRecord: profaneHuman)
        
        switch resultHuman {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.profanityDetected))
        default:
            XCTFail("Profanity should return .invalid result")
        }
        
        // Profanity in dog translation
        let profaneDog = TranslationRecord(
            humanText: "sit",
            dogTranslation: "badword2"
        )
        let resultDog = validationService.validate(translationRecord: profaneDog)
        
        switch resultDog {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.profanityDetected))
        default:
            XCTFail("Profanity should return .invalid result")
        }
    }
    
    func testEnglishLanguageDetection() throws {
        // Non-English human text
        let nonEnglishHuman = TranslationRecord(
            humanText: "我爱你", // Chinese for "I love you"
            dogTranslation: "woof woof woof"
        )
        let resultHuman = validationService.validate(translationRecord: nonEnglishHuman)
        
        switch resultHuman {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.notEnglish))
        default:
            XCTFail("Non-English text should return .invalid result")
        }
        
        // Non-English dog translation
        let nonEnglishDog = TranslationRecord(
            humanText: "sit",
            dogTranslation: "我爱你"
        )
        let resultDog = validationService.validate(translationRecord: nonEnglishDog)
        
        switch resultDog {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.notEnglish))
        default:
            XCTFail("Non-English text should return .invalid result")
        }
    }
    
    func testDuplicateDetection() throws {
        // First submission (should be valid)
        let firstSubmission = TranslationRecord(
            humanText: "sit",
            dogTranslation: "woof woof woof"
        )
        let firstResult = validationService.validate(translationRecord: firstSubmission)
        
        switch firstResult {
        case .valid:
            break // First submission should be valid
        default:
            XCTFail("First submission should be valid")
        }
        
        // Duplicate submission (should be invalid)
        let duplicateSubmission = TranslationRecord(
            humanText: "sit",
            dogTranslation: "woof woof woof"
        )
        let duplicateResult = validationService.validate(translationRecord: duplicateSubmission)
        
        switch duplicateResult {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.duplicateTranslation))
        default:
            XCTFail("Duplicate submission should return .invalid result")
        }
    }
    
    func testConfidenceScoring() throws {
        // High confidence translation
        let highConfidence = TranslationRecord(
            humanText: "sit",
            dogTranslation: "woof woof woof"
        )
        let highResult = validationService.validate(translationRecord: highConfidence)
        
        switch highResult {
        case .valid(let qualityScore):
            XCTAssertTrue(qualityScore > 0.7, "High confidence translation should have score > 0.7")
        case .invalid, .warning:
            XCTFail("High confidence translation should return .valid result")
        }
        
        // Low confidence translation
        let lowConfidence = TranslationRecord(
            humanText: "sit",
            dogTranslation: "bark bark bark"
        )
        let lowResult = validationService.validate(translationRecord: lowConfidence)
        
        switch lowResult {
        case .warning(let qualityScore, let warnings):
            XCTAssertTrue(qualityScore < 0.7, "Low confidence translation should have score < 0.7")
            XCTAssertTrue(warnings.contains(.lowQuality(qualityScore: qualityScore)))
        case .invalid, .valid:
            XCTFail("Low confidence translation should return .warning result")
        }
    }
    
    func testMLModelFallback() throws {
        // Test that the service handles ML model failures gracefully
        // We'll simulate this by temporarily making the ML model unavailable
        
        // First, test with ML model working
        let normalTranslation = TranslationRecord(
            humanText: "sit",
            dogTranslation: "woof woof woof"
        )
        let normalResult = validationService.validate(translationRecord: normalTranslation)
        
        switch normalResult {
        case .valid, .warning:
            break // Should work normally
        case .invalid(let errors):
            XCTAssertFalse(errors.contains(.lowConfidence), "Should not have low confidence error with working ML model")
        }
        
        // Test with ML model failure (simulated by making TranslationModels unavailable)
        // Note: This is a conceptual test - in reality we'd need to mock the ML model
        // For now, we'll test that the fallback confidence scoring works
        
        // Create a translation that would normally fail ML confidence
        let poorQuality = TranslationRecord(
            humanText: "sit",
            dogTranslation: "bark"
        )
        let poorResult = validationService.validate(translationRecord: poorQuality)
        
        switch poorResult {
        case .warning(let qualityScore, let warnings):
            XCTAssertTrue(qualityScore < 0.7, "Poor quality translation should have low score")
            XCTAssertTrue(warnings.contains(.lowQuality(qualityScore: qualityScore)))
        case .invalid, .valid:
            XCTFail("Poor quality translation should return .warning result")
        }
    }
    
    func testValidationPerformance() throws {
        measure {
            let translation = TranslationRecord(
                humanText: "sit",
                dogTranslation: "woof woof woof"
            )
            _ = validationService.validate(translationRecord: translation)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testMaximumLengthInputs() throws {
        let maxHuman = TranslationRecord(
            humanText: String(repeating: "a", count: 100), // Exactly 100 chars
            dogTranslation: "woof woof woof"
        )
        let maxDog = TranslationRecord(
            humanText: "sit",
            dogTranslation: String(repeating: "woof ", count: 25) // 125 chars (too long)
        )
        
        // Max human should be valid
        let maxHumanResult = validationService.validate(translationRecord: maxHuman)
        switch maxHumanResult {
        case .valid, .warning:
            break
        case .invalid:
            XCTFail("Maximum length human text should be valid")
        }
        
        // Max dog should be invalid (too long)
        let maxDogResult = validationService.validate(translationRecord: maxDog)
        switch maxDogResult {
        case .invalid(let errors):
            XCTAssertTrue(errors.contains(.tooLong(field: "dogTranslation", maxLength: 50, actualLength: 125)))
        default:
            XCTFail("Maximum length dog translation should be invalid")
        }
    }
    
    func testUnicodeAndSpecialCharacters() throws {
        // Test with special characters that should be allowed
        let specialChars = TranslationRecord(
            humanText: "sit! @#$",
            dogTranslation: "woof woof woof!"
        )
        let result = validationService.validate(translationRecord: specialChars)
        
        switch result {
        case .valid, .warning:
            break // Special characters should be allowed
        case .invalid:
            XCTFail("Special characters should not cause validation failure")
        }
    }
    
    func testMixedCaseText() throws {
        // Test that validation is case-insensitive where appropriate
        let mixedCase = TranslationRecord(
            humanText: "SIT",
            dogTranslation: "WOOF WOOF WOOF"
        )
        let result = validationService.validate(translationRecord: mixedCase)
        
        switch result {
        case .valid, .warning:
            break // Case should not affect validation
        case .invalid:
            XCTFail("Mixed case text should not cause validation failure")
        }
    }
}