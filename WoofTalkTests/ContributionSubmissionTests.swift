// MARK: - ContributionSubmissionTests

import XCTest
import CoreData
@testable import WoofTalk

final class ContributionSubmissionTests: XCTestCase {
    
    // MARK: - Properties
    
    private var coreDataContext: NSManagedObjectContext!
    private var contributionManager: ContributionManager!
    private var communityPhraseManager: CommunityPhraseManager!
    private var userProfileManager: UserProfileManager!
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        // Setup in-memory Core Data stack for testing
        coreDataContext = PersistenceController.shared.container.viewContext
        contributionManager = ContributionManager(coreDataContext: coreDataContext, contributionSyncManager: MockContributionSyncManager())
        communityPhraseManager = CommunityPhraseManager(coreDataContext: coreDataContext)
        userProfileManager = UserProfileManager(coreDataContext: coreDataContext)
        
        // Create test users
        let moderator = User.create(username: "moderator", email: "mod@example.com", isModerator: true)
        let regularUser = User.create(username: "user", email: "user@example.com", isModerator: false)
        
        // Save test users
        try coreDataContext.save()
    }
    
    override func tearDownWithError() throws {
        // Clean up Core Data
        coreDataContext.reset()
    }
    
    // MARK: - Test Cases
    
    func testContributionSubmissionWithValidation() throws {
        // Given: A valid translation record
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        
        // When: Submit translation
        let expectation = XCTestExpectation(description: "Contribution submission completes")
        
        contributionManager.submitTranslation(translationRecord) { result in
            // Then: Should succeed
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Contribution submission should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Contribution should be created in Core Data
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        let contributions = try coreDataContext.fetch(fetchRequest)
        
        XCTAssertFalse(contributions.isEmpty, "Contribution should be created in Core Data")
        XCTAssertEqual(contributions.count, 1, "Should have exactly one contribution")
        
        let contribution = contributions.first!
        XCTAssertEqual(contribution.humanText, "Hello", "Contribution should have correct human text")
        XCTAssertEqual(contribution.dogTranslation, "Woof woof", "Contribution should have correct dog translation")
        XCTAssertEqual(contribution.displayStatus, .pending, "Contribution should have pending status")
        XCTAssertNotNil(contribution.timestamp, "Contribution should have timestamp")
        XCTAssertNotNil(contribution.id, "Contribution should have ID")
    }
    
    func testContributionSubmissionWithValidationWarnings() throws {
        // Given: A translation with low quality
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "W")
        
        // When: Submit translation
        let expectation = XCTestExpectation(description: "Contribution submission completes")
        
        contributionManager.submitTranslation(translationRecord) { result in
            // Then: Should succeed with warnings
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Contribution submission should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Contribution should be created with warnings
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        let contributions = try coreDataContext.fetch(fetchRequest)
        
        XCTAssertFalse(contributions.isEmpty, "Contribution should be created in Core Data")
        XCTAssertEqual(contributions.count, 1, "Should have exactly one contribution")
        
        let contribution = contributions.first!
        XCTAssertEqual(contribution.humanText, "Hello", "Contribution should have correct human text")
        XCTAssertEqual(contribution.dogTranslation, "W", "Contribution should have correct dog translation")
        XCTAssertEqual(contribution.displayStatus, .pending, "Contribution should have pending status")
        XCTAssertNotNil(contribution.validationWarnings, "Contribution should have validation warnings")
        XCTAssertNotNil(contribution.qualityScore, "Contribution should have quality score")
    }
    
    func testContributionSubmissionWithValidationErrors() throws {
        // Given: An invalid translation record (empty fields)
        let translationRecord = TranslationRecord(humanText: "", dogTranslation: "")
        
        // When: Submit translation
        let expectation = XCTestExpectation(description: "Contribution submission completes")
        
        contributionManager.submitTranslation(translationRecord) { result in
            // Then: Should fail with validation errors
            switch result {
            case .success:
                XCTFail("Contribution submission should fail with empty fields")
            case .failure(let error):
                guard case .validationFailed = error else {
                    XCTFail("Should fail with validationFailed error")
                    return
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then: No contribution should be created
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        let contributions = try coreDataContext.fetch(fetchRequest)
        
        XCTAssertTrue(contributions.isEmpty, "No contribution should be created with invalid data")
    }
    
    func testContributionSubmissionOffline() throws {
        // Given: Mock contribution sync manager with network unavailable
        let mockSyncManager = MockContributionSyncManager(networkAvailable: false)
        let contributionManager = ContributionManager(coreDataContext: coreDataContext, contributionSyncManager: mockSyncManager)
        
        // When: Submit translation while offline
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        
        let expectation = XCTestExpectation(description: "Contribution submission completes")
        
        contributionManager.submitTranslation(translationRecord) { result in
            // Then: Should succeed but with network unavailable warning
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Contribution submission should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Contribution should be created in Core Data
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        let contributions = try coreDataContext.fetch(fetchRequest)
        
        XCTAssertFalse(contributions.isEmpty, "Contribution should be created in Core Data")
        XCTAssertEqual(contributions.count, 1, "Should have exactly one contribution")
        
        let contribution = contributions.first!
        XCTAssertEqual(contribution.humanText, "Hello", "Contribution should have correct human text")
        XCTAssertEqual(contribution.dogTranslation, "Woof woof", "Contribution should have correct dog translation")
        XCTAssertEqual(contribution.displayStatus, .pending, "Contribution should have pending status")
        XCTAssertNotNil(contribution.timestamp, "Contribution should have timestamp")
        XCTAssertNotNil(contribution.id, "Contribution should have ID")
    }
    
    func testContributionValidationService() throws {
        // Given: Test translation records
        let validRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let emptyRecord = TranslationRecord(humanText: "", dogTranslation: "")
        let shortRecord = TranslationRecord(humanText: "H", dogTranslation: "W")
        let longRecord = TranslationRecord(humanText: String(repeating: "A", count: 101), dogTranslation: String(repeating: "B", count: 101))
        let profanityRecord = TranslationRecord(humanText: "badword1", dogTranslation: "Woof woof")
        
        // When: Validate records
        let validator = ContributionValidationService()
        
        // Then: Valid record should pass
        let validResult = validator.validate(translationRecord: validRecord)
        if case .valid = validResult {
            // Success
        } else {
            XCTFail("Valid record should pass validation")
        }
        
        // Then: Empty record should fail
        let emptyResult = validator.validate(translationRecord: emptyRecord)
        if case .invalid(let errors) = emptyResult {
            XCTAssertFalse(errors.isEmpty, "Should have validation errors for empty record")
        } else {
            XCTFail("Empty record should fail validation")
        }
        
        // Then: Short record should fail
        let shortResult = validator.validate(translationRecord: shortRecord)
        if case .invalid(let errors) = shortResult {
            XCTAssertFalse(errors.isEmpty, "Should have validation errors for short record")
        } else {
            XCTFail("Short record should fail validation")
        }
        
        // Then: Long record should fail
        let longResult = validator.validate(translationRecord: longRecord)
        if case .invalid(let errors) = longResult {
            XCTAssertFalse(errors.isEmpty, "Should have validation errors for long record")
        } else {
            XCTFail("Long record should fail validation")
        }
        
        // Then: Profanity record should fail
        let profanityResult = validator.validate(translationRecord: profanityRecord)
        if case .invalid(let errors) = profanityResult {
            XCTAssertFalse(errors.isEmpty, "Should have validation errors for profanity record")
        } else {
            XCTFail("Profanity record should fail validation")
        }
    }
    
    func testContributionDuplicatePrevention() throws {
        // Given: Existing contribution
        let existingRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let contribution = Contribution.create(from: existingRecord, user: User.mockUser, qualityScore: 0.9, warnings: [])
        contribution.displayStatus = .pending
        
        try coreDataContext.save()
        
        // When: Attempt to create duplicate contribution
        let duplicateRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let contributionManager = ContributionManager(coreDataContext: coreDataContext, contributionSyncManager: MockContributionSyncManager())
        
        let expectation = XCTestExpectation(description: "Contribution submission completes")
        
        contributionManager.submitTranslation(duplicateRecord) { result in
            // Then: Should succeed but with duplicate warning
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Contribution submission should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Contribution should be created but marked as duplicate
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        let contributions = try coreDataContext.fetch(fetchRequest)
        
        XCTAssertFalse(contributions.isEmpty, "Contribution should be created in Core Data")
        XCTAssertEqual(contributions.count, 2, "Should have exactly two contributions")
        
        let duplicateContribution = contributions.last!
        XCTAssertEqual(duplicateContribution.humanText, "Hello", "Duplicate contribution should have correct human text")
        XCTAssertEqual(duplicateContribution.dogTranslation, "Woof woof", "Duplicate contribution should have correct dog translation")
        XCTAssertEqual(duplicateContribution.displayStatus, .pending, "Duplicate contribution should have pending status")
        XCTAssertNotNil(duplicateContribution.validationWarnings, "Duplicate contribution should have validation warnings")
        XCTAssertNotNil(duplicateContribution.qualityScore, "Duplicate contribution should have quality score")
    }
    
    func testContributionQualityScoring() throws {
        // Given: Test translation records with different qualities
        let highQualityRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let mediumQualityRecord = TranslationRecord(humanText: "Hello", dogTranslation: "W")
        let lowQualityRecord = TranslationRecord(humanText: "H", dogTranslation: "W")
        
        let validator = ContributionValidationService()
        
        // When: Validate records
        let highResult = validator.validate(translationRecord: highQualityRecord)
        let mediumResult = validator.validate(translationRecord: mediumQualityRecord)
        let lowResult = validator.validate(translationRecord: lowQualityRecord)
        
        // Then: Should get quality scores
        var highScore: Double?
        var mediumScore: Double?
        var lowScore: Double?
        
        if case .valid(let qualityScore) = highResult {
            highScore = qualityScore
        }
        
        if case .warning(let qualityScore, _) = mediumResult {
            mediumScore = qualityScore
        }
        
        if case .warning(let qualityScore, _) = lowResult {
            lowScore = qualityScore
        }
        
        XCTAssertNotNil(highScore, "Should get quality score for high quality")
        XCTAssertNotNil(mediumScore, "Should get quality score for medium quality")
        XCTAssertNotNil(lowScore, "Should get quality score for low quality")
        
        // Then: Scores should be in valid range
        XCTAssertGreaterThanOrEqual(highScore ?? 0, 0.0, "Quality score should be >= 0")
        XCTAssertLessThanOrEqual(highScore ?? 0, 1.0, "Quality score should be <= 1")
        XCTAssertGreaterThanOrEqual(mediumScore ?? 0, 0.0, "Quality score should be >= 0")
        XCTAssertLessThanOrEqual(mediumScore ?? 0, 1.0, "Quality score should be <= 1")
        XCTAssertGreaterThanOrEqual(lowScore ?? 0, 0.0, "Quality score should be >= 0")
        XCTAssertLessThanOrEqual(lowScore ?? 0, 1.0, "Quality score should be <= 1")
        
        // Then: Scores should be in correct order
        XCTAssertGreaterThanOrEqual(highScore ?? 0, mediumScore ?? 0, "High quality should have higher score")
        XCTAssertGreaterThanOrEqual(mediumScore ?? 0, lowScore ?? 0, "Medium quality should have higher score")
    }
    
    func testContributionManagerErrorHandling() throws {
        // Given: Test translation records
        let validRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let emptyRecord = TranslationRecord(humanText: "", dogTranslation: "")
        let profanityRecord = TranslationRecord(humanText: "badword1", dogTranslation: "Woof woof")
        
        // When: Validate records
        let contributionManager = ContributionManager(coreDataContext: coreDataContext, contributionSyncManager: MockContributionSyncManager())
        
        // Then: Valid record should succeed
        let validExpectation = XCTestExpectation(description: "Valid contribution submission")
        
        contributionManager.submitTranslation(validRecord) { result in
            switch result {
            case .success:
                validExpectation.fulfill()
            case .failure:
                XCTFail("Valid record should succeed")
            }
        }
        
        // Then: Empty record should fail
        let emptyExpectation = XCTestExpectation(description: "Empty contribution submission")
        
        contributionManager.submitTranslation(emptyRecord) { result in
            switch result {
            case .success:
                XCTFail("Empty record should fail")
            case .failure(let error):
                guard case .validationFailed = error else {
                    XCTFail("Should fail with validationFailed error")
                    return
                }
                emptyExpectation.fulfill()
            }
        }
        
        // Then: Profanity record should fail
        let profanityExpectation = XCTestExpectation(description: "Profanity contribution submission")
        
        contributionManager.submitTranslation(profanityRecord) { result in
            switch result {
            case .success:
                XCTFail("Profanity record should fail")
            case .failure(let error):
                guard case .validationFailed = error else {
                    XCTFail("Should fail with validationFailed error")
                    return
                }
                profanityExpectation.fulfill()
            }
        }
        
        wait(for: [validExpectation, emptyExpectation, profanityExpectation], timeout: 3.0)
    }
}