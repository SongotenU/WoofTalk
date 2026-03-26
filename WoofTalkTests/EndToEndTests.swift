// MARK: - EndToEndTests

import XCTest
@testable import WoofTalk

/// End-to-end tests covering complete user journeys from sign-in to social features
final class EndToEndTests: XCTestCase {
    
    // MARK: - Properties
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var translationEngine: TranslationEngine!
    var contributionManager: ContributionManager!
    var communityPhraseManager: CommunityPhraseManager!
    var userProfileManager: UserProfileManager!
    var socialGraphManager: SocialGraphManager!
    var moderationService: AutoModerationService!
    
    // MARK: - Lifecycle
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize test environment
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        translationEngine = TranslationEngine()
        contributionManager = ContributionManager(context: viewContext)
        communityPhraseManager = CommunityPhraseManager(context: viewContext)
        userProfileManager = UserProfileManager(context: viewContext)
        socialGraphManager = SocialGraphManager(context: viewContext)
        moderationService = AutoModerationService()
    }
    
    override func tearDown() async throws {
        // Clean up
        viewContext = nil
        persistenceController = nil
        translationEngine = nil
        contributionManager = nil
        communityPhraseManager = nil
        userProfileManager = nil
        socialGraphManager = nil
        moderationService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Test: Complete User Journey
    
    /// Test: Sign in → Submit contribution → Moderation → Browse → Social
    func testCompleteUserJourney() async throws {
        // Step 1: User Sign-in / Profile Creation
        let user = try await createTestUser(username: "testuser_e2e")
        XCTAssertNotNil(user, "User should be created")
        XCTAssertEqual(user.username, "testuser_e2e")
        
        // Step 2: Submit Contribution
        let contribution = try await submitTestContribution(
            userId: user.id,
            phrase: "Hello my good boy",
            translation: "Woof woof!",
            context: "Greeting"
        )
        XCTAssertNotNil(contribution, "Contribution should be created")
        
        // Step 3: Moderation
        let moderationResult = try await moderationService.moderateContribution(contribution)
        XCTAssertTrue(moderationResult.isApproved, "Contribution should be approved")
        
        // Step 4: Community phrase appears in browse
        let communityPhrases = try await fetchCommunityPhrases()
        let foundPhrase = communityPhrases.first { $0.id == contribution.id }
        XCTAssertNotNil(foundPhrase, "Submitted phrase should appear in community")
        
        // Step 5: Social features - like and share
        try await testSocialInteractions(phraseId: contribution.id, userId: user.id)
    }
    
    // MARK: - Test: Sign-in to Profile
    
    func testSignInCreatesProfile() async throws {
        let user = try await createTestUser(username: "newuser")
        
        XCTAssertNotNil(user)
        XCTAssertEqual(user.username, "newuser")
        XCTAssertNotNil(user.createdAt)
        XCTAssertEqual(user.contributionCount, 0)
        XCTAssertEqual(user.reputationScore, 0)
    }
    
    // MARK: - Test: Contribution Submission Flow
    
    func testContributionSubmissionFlow() async throws {
        let user = try await createTestUser(username: "contributor")
        
        // Submit multiple contributions
        let testPhrases = [
            ("Sit", "Woof woof", "Command"),
            ("Good boy", "Yip yip", "Praise"),
            ("Let's play", "Woof woof woof!", "Invitation")
        ]
        
        for (phrase, translation, context) in testPhrases {
            let contribution = try await submitTestContribution(
                userId: user.id,
                phrase: phrase,
                translation: translation,
                context: context
            )
            XCTAssertNotNil(contribution, "Contribution '\(phrase)' should be created")
        }
        
        // Verify total contributions
        let fetchedUser = try await fetchUser(id: user.id)
        XCTAssertEqual(fetchedUser?.contributionCount, 3, "User should have 3 contributions")
    }
    
    // MARK: - Test: Moderation Flow
    
    func testModerationApprovesValidContribution() async throws {
        let user = try await createTestUser(username: "moderation_test")
        
        let contribution = try await submitTestContribution(
            userId: user.id,
            phrase: "Good dog",
            translation: "Woof",
            context: "Positive"
        )
        
        let result = try await moderationService.moderateContribution(contribution)
        XCTAssertTrue(result.isApproved, "Valid contribution should be approved")
        XCTAssertNil(result.rejectionReason, "No rejection reason for valid content")
    }
    
    func testModerationRejectsSpamContent() async throws {
        let user = try await createTestUser(username: "spam_test")
        
        let spamContribution = try await submitTestContribution(
            userId: user.id,
            phrase: "Buy cheap meds now! Click here!!!",
            translation: "Woof",
            context: "Spam"
        )
        
        let result = try await moderationService.moderateContribution(spamContribution)
        
        // AutoModeration should catch spam
        XCTAssertFalse(result.isApproved, "Spam should be rejected")
    }
    
    // MARK: - Test: Community Browser
    
    func testCommunityBrowserFetchesPhrases() async throws {
        // First add some community phrases
        let user1 = try await createTestUser(username: "user1")
        let user2 = try await createTestUser(username: "user2")
        
        _ = try await submitTestContribution(userId: user1.id, phrase: "Sit", translation: "Woof", context: "Command")
        _ = try await submitTestContribution(userId: user2.id, phrase: "Stay", translation: "Woof woof", context: "Command")
        
        // Fetch community phrases
        let phrases = try await fetchCommunityPhrases()
        XCTAssertGreaterThan(phrases.count, 0, "Should have community phrases")
    }
    
    func testCommunityBrowserFiltersByCategory() async throws {
        // Add phrases in different categories
        let user = try await createTestUser(username: "filter_test")
        
        _ = try await submitTestContribution(userId: user.id, phrase: "Sit", translation: "Woof", context: "Command")
        _ = try await submitTestContribution(userId: user.id, phrase: "Hungry", translation: "Whine", context: "Needs")
        
        // Verify filtering logic
        let allPhrases = try await fetchCommunityPhrases()
        let commandPhrases = allPhrases.filter { $0.category == "Command" }
        let needsPhrases = allPhrases.filter { $0.category == "Needs" }
        
        XCTAssertGreaterThan(commandPhrases.count, 0, "Should have command phrases")
        XCTAssertGreaterThan(needsPhrases.count, 0, "Should have needs phrases")
    }
    
    // MARK: - Test: Social Features
    
    func testSocialInteractions() async throws {
        let user1 = try await createTestUser(username: "social_user1")
        let user2 = try await createTestUser(username: "social_user2")
        
        let contribution = try await submitTestContribution(
            userId: user1.id,
            phrase: "Play time",
            translation: "Yip!",
            context: "Activity"
        )
        
        // User 2 follows User 1
        try await socialGraphManager.follow(userId: user2.id, targetUserId: user1.id)
        
        // User 2 likes the contribution
        try await socialGraphManager.likePhrase(phraseId: contribution.id, userId: user2.id)
        
        // Verify following
        let isFollowing = try await socialGraphManager.isFollowing(userId: user2.id, targetUserId: user1.id)
        XCTAssertTrue(isFollowing, "User 2 should be following User 1")
        
        // Verify like
        let phrase = try await fetchCommunityPhrase(id: contribution.id)
        XCTAssertEqual(phrase?.likeCount, 1, "Phrase should have 1 like")
    }
    
    func testLeaderboardRankings() async throws {
        // Create users with different contribution counts
        let topContributor = try await createTestUser(username: "top_contributor")
        
        // Add contributions to increase reputation
        for i in 0..<10 {
            _ = try await submitTestContribution(
                userId: topContributor.id,
                phrase: "Phrase \(i)",
                translation: "Woof",
                context: "Test"
            )
        }
        
        // Get leaderboard
        let leaderboard = try await fetchLeaderboard()
        XCTAssertGreaterThan(leaderboard.count, 0, "Leaderboard should have entries")
        
        // Top contributor should be first
        if let first = leaderboard.first {
            XCTAssertEqual(first.id, topContributor.id, "Top contributor should be first")
        }
    }
    
    // MARK: - Test: Offline-First Journey
    
    func testOfflineJourneyWhenOnline() async throws {
        // Simulate online state
        let isOnline = await checkConnectivity()
        XCTAssertTrue(isOnline, "Should be online")
        
        // Create contribution (should sync)
        let user = try await createTestUser(username: "offline_test")
        let contribution = try await submitTestContribution(
            userId: user.id,
            phrase: "Walk",
            translation: "Woof woof",
            context: "Activity"
        )
        
        // Verify it was saved locally
        let localPhrases = try await fetchLocalPhrases()
        XCTAssertTrue(localPhrases.contains { $0.id == contribution.id }, "Contribution should be stored locally")
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser(username: String) async throws -> TestUser {
        let user = TestUser(
            id: UUID().uuidString,
            username: username,
            createdAt: Date(),
            contributionCount: 0,
            reputationScore: 0
        )
        
        userProfileManager.createUser(user)
        
        return user
    }
    
    private func submitTestContribution(userId: String, phrase: String, translation: String, context: String) async throws -> TestContribution {
        let contribution = TestContribution(
            id: UUID().uuidString,
            userId: userId,
            phrase: phrase,
            translation: translation,
            context: context,
            createdAt: Date(),
            status: .pending
        )
        
        try contributionManager.submitContribution(contribution)
        
        return contribution
    }
    
    private func fetchCommunityPhrases() async throws -> [TestCommunityPhrase] {
        return communityPhraseManager.fetchAllPhrases()
    }
    
    private func fetchCommunityPhrase(id: String) async throws -> TestCommunityPhrase? {
        return communityPhraseManager.fetchPhrase(id: id)
    }
    
    private func fetchUser(id: String) async throws -> TestUser? {
        return userProfileManager.fetchUser(id: id)
    }
    
    private func fetchLeaderboard() async throws -> [TestUser] {
        return LeaderboardManager.shared.fetchTopUsers()
    }
    
    private func fetchLocalPhrases() async throws -> [TestCommunityPhrase] {
        return communityPhraseManager.fetchLocalPhrases()
    }
    
    private func checkConnectivity() async -> Bool {
        // Check network reachability
        return NetworkMonitor.shared.isConnected
    }
}

// MARK: - Test Models

struct TestUser {
    let id: String
    let username: String
    let createdAt: Date
    var contributionCount: Int
    var reputationScore: Int
}

struct TestContribution {
    let id: String
    let userId: String
    let phrase: String
    let translation: String
    let context: String
    let createdAt: Date
    var status: ContributionStatus
}

enum ContributionStatus {
    case pending
    case approved
    case rejected
}

struct TestCommunityPhrase {
    let id: String
    let phrase: String
    let translation: String
    let category: String
    let authorId: String
    let likeCount: Int
    let createdAt: Date
}

// MARK: - E2E Test Helpers

enum E2ETestHelpers {
    /// Generates test data for E2E tests
    static func generateTestPhrases(count: Int) -> [(phrase: String, translation: String, context: String)] {
        let basePhrases = [
            ("Hello", "Woof woof!", "Greeting"),
            ("Sit", "Woof!", "Command"),
            ("Stay", "Woof woof", "Command"),
            ("Come", "Yip yip!", "Command"),
            ("Good boy", "Woof woof woof!", "Praise"),
            ("Good girl", "Yip!", "Praise"),
            ("Let's play", "Woof woof!", "Invitation"),
            ("Walk", "Woof woof woof!", "Activity"),
            ("Food", "Whine whine!", "Needs"),
            ("Water", "Whine!", "Needs")
        ]
        
        var results: [(String, String, String)] = []
        for i in 0..<count {
            let index = i % basePhrases.count
            results.append((basePhrases[index].0, basePhrases[index].1, basePhrases[index].2))
        }
        return results
    }
    
    /// Wait for async operation with timeout
    static func waitForResult<T>(
        maxDuration: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < maxDuration {
            do {
                return try await operation()
            } catch {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }
        
        throw E2ETimeoutError()
    }
}

struct E2ETimeoutError: Error {
    let message = "E2E test operation timed out"
}