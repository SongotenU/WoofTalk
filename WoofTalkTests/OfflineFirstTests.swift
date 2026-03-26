// MARK: - OfflineFirstTests

import XCTest
@testable import WoofTalk

final class OfflineFirstTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var viewContext: NSManagedObjectContext!
    var offlineManager: OfflineTranslationManager!
    var contributionManager: ContributionManager!
    var communityPhraseManager: CommunityPhraseManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
        
        offlineManager = OfflineTranslationManager.shared
        contributionManager = ContributionManager(context: viewContext)
        communityPhraseManager = CommunityPhraseManager(context: viewContext)
    }
    
    override func tearDown() async throws {
        viewContext = nil
        persistenceController = nil
        offlineManager = nil
        contributionManager = nil
        communityPhraseManager = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Test: Translation Works Offline
    
    func testTranslationWorksOffline() async throws {
        offlineManager.setOnlineStatus(false)
        
        let result = offlineManager.translateOffline(phrase: "sit", direction: .humanToDog)
        
        XCTAssertNotNil(result, "Offline translation should return result")
    }
    
    // MARK: - Test: Contributions Queue Offline
    
    func testContributionQueuesWhenOffline() async throws {
        offlineManager.setOnlineStatus(false)
        
        let pendingCount = offlineManager.getPendingSyncCount()
        
        XCTAssertEqual(pendingCount, 0, "Initially no pending items")
        
        let contribution = createTestContribution(phrase: "Test", translation: "Woof")
        try offlineManager.queueContributionForSync(contribution)
        
        let newPendingCount = offlineManager.getPendingSyncCount()
        XCTAssertEqual(newPendingCount, 1, "Should have 1 pending item after queuing")
    }
    
    // MARK: - Test: Sync When Coming Online
    
    func testSyncTriggersWhenOnline() async throws {
        offlineManager.setOnlineStatus(false)
        
        let contribution = createTestContribution(phrase: "Hello", translation: "Woof woof")
        try offlineManager.queueContributionForSync(contribution)
        
        offlineManager.setOnlineStatus(true)
        
        let synced = offlineManager.processPendingSync()
        XCTAssertTrue(synced, "Sync should process when online")
    }
    
    // MARK: - Test: Offline Indicator
    
    func testOfflineIndicatorShowsWhenOffline() async throws {
        offlineManager.setOnlineStatus(false)
        
        let shouldShow = offlineManager.shouldShowOfflineIndicator()
        XCTAssertTrue(shouldShow, "Offline indicator should show when offline")
        
        offlineManager.setOnlineStatus(true)
        
        let shouldShowWhenOnline = offlineManager.shouldShowOfflineIndicator()
        XCTAssertFalse(shouldShowWhenOnline, "Offline indicator should not show when online")
    }
    
    // MARK: - Test: Local Cache Available Offline
    
    func testLocalCacheAvailableOffline() async throws {
        offlineManager.setOnlineStatus(false)
        
        let cached = offlineManager.getCachedTranslation(for: "sit")
        
        XCTAssertNotNil(cached, "Cached translations should be available offline")
    }
    
    // MARK: - Test: Conflict Resolution
    
    func testConflictResolutionHandlesDuplicates() async throws {
        let localContribution = createTestContribution(phrase: "Test", translation: "Woof")
        let remoteContribution = createTestContribution(phrase: "Test", translation: "Yip")
        
        let resolved = offlineManager.resolveConflict(local: localContribution, remote: remoteContribution)
        
        XCTAssertNotNil(resolved, "Conflict resolution should return result")
    }
    
    // MARK: - Test: All Features Work Offline
    
    func testTranslationOffline() async throws {
        offlineManager.setOnlineStatus(false)
        
        let result = offlineManager.translateOffline(phrase: "good boy", direction: .humanToDog)
        XCTAssertNotNil(result)
    }
    
    func testBrowsePhrasesOffline() async throws {
        offlineManager.setOnlineStatus(false)
        
        let phrases = communityPhraseManager.fetchLocalPhrases()
        XCTAssertNotNil(phrases, "Should fetch local phrases offline")
    }
    
    func testHistoryAccessOffline() async throws {
        offlineManager.setOnlineStatus(false)
        
        let history = offlineManager.getTranslationHistory()
        XCTAssertNotNil(history, "Should access history offline")
    }
    
    // MARK: - Helpers
    
    private func createTestContribution(phrase: String, translation: String) -> TestOfflineContribution {
        return TestOfflineContribution(
            id: UUID().uuidString,
            phrase: phrase,
            translation: translation,
            createdAt: Date(),
            synced: false
        )
    }
}

struct TestOfflineContribution {
    let id: String
    let phrase: String
    let translation: String
    let createdAt: Date
    var synced: Bool
}