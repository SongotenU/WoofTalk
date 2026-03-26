// MARK: - ModerationFlowTests

import XCTest
import CoreData
@testable import WoofTalk

final class ModerationFlowTests: XCTestCase {
    
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
    
    func testApproveContributionCreatesCommunityPhrase() throws {
        // Given: A pending contribution
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let contribution = Contribution.create(from: translationRecord, user: User.mockUser, qualityScore: 0.9, warnings: [])
        contribution.displayStatus = .pending
        
        try coreDataContext.save()
        
        // When: Moderator approves the contribution
        let contributionCopy = try coreDataContext.existingObject(with: contribution.id!) as! Contribution
        try contributionCopy.approve(by: User.mockUser)
        
        // Then: Community phrase should be created
        let existingPhrase = communityPhraseManager.findExistingCommunityPhrase(for: "Hello", direction: "en-dog")
        XCTAssertNotNil(existingPhrase, "Community phrase should be created when contribution is approved")
        XCTAssertEqual(existingPhrase?.humanText, "Hello", "Community phrase should have correct human text")
        XCTAssertEqual(existingPhrase?.dogTranslation, "Woof woof", "Community phrase should have correct dog translation")
        XCTAssertEqual(existingPhrase?.qualityScore, 0.9, "Community phrase should have correct quality score")
        XCTAssertEqual(existingPhrase?.submitter, User.mockUser, "Community phrase should have correct submitter")
        
        // And: Contribution status should be updated
        XCTAssertEqual(contributionCopy.displayStatus, .processed, "Contribution status should be updated to processed")
    }
    
    func testRejectContributionDoesNotCreateCommunityPhrase() throws {
        // Given: A pending contribution
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let contribution = Contribution.create(from: translationRecord, user: User.mockUser, qualityScore: 0.9, warnings: [])
        contribution.displayStatus = .pending
        
        try coreDataContext.save()
        
        // When: Moderator rejects the contribution
        let contributionCopy = try coreDataContext.existingObject(with: contribution.id!) as! Contribution
        try contributionCopy.reject(by: User.mockUser)
        
        // Then: No community phrase should be created
        let existingPhrase = communityPhraseManager.findExistingCommunityPhrase(for: "Hello", direction: "en-dog")
        XCTAssertNil(existingPhrase, "Community phrase should not be created when contribution is rejected")
        
        // And: Contribution status should be updated
        XCTAssertEqual(contributionCopy.displayStatus, .rejected, "Contribution status should be updated to rejected")
    }
    
    func testDuplicatePrevention() throws {
        // Given: An existing community phrase
        let existingPhrase = CommunityPhrase.create(
            humanText: "Hello",
            dogTranslation: "Woof woof",
            qualityScore: 0.9,
            direction: "en-dog",
            submitter: User.mockUser,
            context: coreDataContext
        )
        
        try coreDataContext.save()
        
        // When: Moderator tries to approve duplicate contribution
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let contribution = Contribution.create(from: translationRecord, user: User.mockUser, qualityScore: 0.9, warnings: [])
        contribution.displayStatus = .pending
        
        try coreDataContext.save()
        
        // When: Approve is attempted
        let contributionCopy = try coreDataContext.existingObject(with: contribution.id!) as! Contribution
        
        do {
            try communityPhraseManager.createCommunityPhrase(from: contributionCopy)
            XCTFail("Should throw duplicate phrase error")
        } catch CommunityPhraseError.duplicatePhrase {
            // Expected error - duplicate phrase detected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Then: Contribution should be marked as duplicate
        XCTAssertEqual(contributionCopy.displayStatus, .duplicate, "Contribution should be marked as duplicate")
        XCTAssertEqual(contributionCopy.validationNotes, "Duplicate of existing community phrase", "Contribution should have duplicate notes")
    }
    
    func testModeratorAccessControl() throws {
        // Given: Test users
        let moderator = User.create(username: "moderator", email: "mod@example.com", isModerator: true)
        let regularUser = User.create(username: "user", email: "user@example.com", isModerator: false)
        
        try coreDataContext.save()
        
        // When: Moderator tries to approve contribution
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let contribution = Contribution.create(from: translationRecord, user: regularUser, qualityScore: 0.9, warnings: [])
        contribution.displayStatus = .pending
        
        try coreDataContext.save()
        
        // When: Approve is attempted
        let contributionCopy = try coreDataContext.existingObject(with: contribution.id!) as! Contribution
        
        do {
            try communityPhraseManager.createCommunityPhrase(from: contributionCopy)
            // Success - moderator can approve
        } catch {
            XCTFail("Moderator should be able to approve contribution: \(error)")
        }
        
        // When: Regular user tries to approve contribution
        let contributionForRegularUser = Contribution.create(from: translationRecord, user: regularUser, qualityScore: 0.9, warnings: [])
        contributionForRegularUser.displayStatus = .pending
        
        try coreDataContext.save()
        
        let contributionCopyForRegularUser = try coreDataContext.existingObject(with: contributionForRegularUser.id!) as! Contribution
        
        do {
            try communityPhraseManager.createCommunityPhrase(from: contributionCopyForRegularUser)
            XCTFail("Regular user should not be able to approve contribution")
        } catch CommunityPhraseError.invalidContribution {
            // Expected error - regular user cannot approve
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testContributionStatusTransitions() throws {
        // Given: A pending contribution
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let contribution = Contribution.create(from: translationRecord, user: User.mockUser, qualityScore: 0.9, warnings: [])
        contribution.displayStatus = .pending
        
        try coreDataContext.save()
        
        // When: Approve is attempted
        let contributionCopy = try coreDataContext.existingObject(with: contribution.id!) as! Contribution
        
        // Then: Should be able to approve
        XCTAssert(contributionCopy.canBeApproved, "Pending contribution should be able to be approved")
        XCTAssertFalse(contributionCopy.canBeRejected, "Pending contribution should be able to be rejected")
        
        // When: Approve is called
        try contributionCopy.approve(by: User.mockUser)
        
        // Then: Status should be approved
        XCTAssertEqual(contributionCopy.displayStatus, .approved, "Contribution status should be approved")
        
        // When: Approve is called again
        do {
            try contributionCopy.approve(by: User.mockUser)
            XCTFail("Should not be able to approve already approved contribution")
        } catch ContributionError.invalidStatusTransition {
            // Expected error - invalid status transition
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // When: Reject is attempted
        do {
            try contributionCopy.reject(by: User.mockUser)
            XCTFail("Should not be able to reject already approved contribution")
        } catch ContributionError.invalidStatusTransition {
            // Expected error - invalid status transition
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCommunityPhraseCreationValidation() throws {
        // Given: Invalid contribution
        let translationRecord = TranslationRecord(humanText: "", dogTranslation: "")
        let contribution = Contribution.create(from: translationRecord, user: User.mockUser, qualityScore: 0.9, warnings: [])
        contribution.displayStatus = .pending
        
        try coreDataContext.save()
        
        // When: Approve is attempted
        let contributionCopy = try coreDataContext.existingObject(with: contribution.id!) as! Contribution
        
        do {
            try communityPhraseManager.createCommunityPhrase(from: contributionCopy)
            XCTFail("Should not be able to create community phrase from invalid contribution")
        } catch CommunityPhraseError.invalidContribution {
            // Expected error - invalid contribution
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testContributionAgeCalculation() throws {
        // Given: A contribution with known timestamp
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let contribution = Contribution.create(from: translationRecord, user: User.mockUser, qualityScore: 0.9, warnings: [])
        contribution.displayStatus = .pending
        contribution.timestamp = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        
        try coreDataContext.save()
        
        // When: Age is calculated
        let contributionCopy = try coreDataContext.existingObject(with: contribution.id!) as! Contribution
        
        // Then: Age should be calculated correctly
        XCTAssertEqual(contributionCopy.ageInDays, 2, "Age in days should be 2")
        XCTAssertEqual(contributionCopy.ageInHours, 48, "Age in hours should be 48")
        XCTAssertGreaterThanOrEqual(contributionCopy.ageInMinutes, 2880, "Age in minutes should be at least 2880")
        
        // Then: Age display should be correct
        let expectedAgeDisplay = "2 day(s) ago"
        XCTAssertEqual(contributionCopy.ageDisplay, expectedAgeDisplay, "Age display should be correct")
    }
    
    func testCommunityPhraseSorting() throws {
        // Given: Multiple community phrases with different quality scores
        let phrase1 = CommunityPhrase.create(
            humanText: "Hello",
            dogTranslation: "Woof woof",
            qualityScore: 0.9,
            direction: "en-dog",
            submitter: User.mockUser,
            context: coreDataContext
        )
        
        let phrase2 = CommunityPhrase.create(
            humanText: "Goodbye",
            dogTranslation: "Woof woof woof",
            qualityScore: 0.95,
            direction: "en-dog",
            submitter: User.mockUser,
            context: coreDataContext
        )
        
        let phrase3 = CommunityPhrase.create(
            humanText: "Thank you",
            dogTranslation: "Woof woof woof woof",
            qualityScore: 0.85,
            direction: "en-dog",
            submitter: User.mockUser,
            context: coreDataContext
        )
        
        try coreDataContext.save()
        
        // When: All phrases are fetched sorted by quality
        let allPhrases = CommunityPhrase.getAllSortedByQuality(context: coreDataContext)
        
        // Then: Should be sorted by quality score descending
        XCTAssertEqual(allPhrases.count, 3, "Should have 3 phrases")
        XCTAssertEqual(allPhrases[0].humanText, "Goodbye", "Highest quality should be first")
        XCTAssertEqual(allPhrases[1].humanText, "Hello", "Second highest quality should be second")
        XCTAssertEqual(allPhrases[2].humanText, "Thank you", "Lowest quality should be third")
    }
    
    func testCommunityPhraseDuplicatePrevention() throws {
        // Given: An existing community phrase
        let existingPhrase = CommunityPhrase.create(
            humanText: "Hello",
            dogTranslation: "Woof woof",
            qualityScore: 0.9,
            direction: "en-dog",
            submitter: User.mockUser,
            context: coreDataContext
        )
        
        try coreDataContext.save()
        
        // When: Attempt to create duplicate
        let translationRecord = TranslationRecord(humanText: "Hello", dogTranslation: "Woof woof")
        let contribution = Contribution.create(from: translationRecord, user: User.mockUser, qualityScore: 0.9, warnings: [])
        contribution.displayStatus = .pending
        
        try coreDataContext.save()
        
        let contributionCopy = try coreDataContext.existingObject(with: contribution.id!) as! Contribution
        
        // When: Approve is attempted
        do {
            try communityPhraseManager.createCommunityPhrase(from: contributionCopy)
            XCTFail("Should throw duplicate phrase error")
        } catch CommunityPhraseError.duplicatePhrase {
            // Expected error - duplicate phrase detected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Then: Contribution should be marked as duplicate
        XCTAssertEqual(contributionCopy.displayStatus, .duplicate, "Contribution should be marked as duplicate")
        XCTAssertEqual(contributionCopy.validationNotes, "Duplicate of existing community phrase", "Contribution should have duplicate notes")
    }
}