// MARK: - SocialFeaturesTests

import XCTest
@testable import WoofTalk

final class SocialFeaturesTests: XCTestCase {
    
    var socialGraphManager: SocialGraphManager!
    var sharingManager: SocialSharingManager!
    var leaderboardManager: LeaderboardManager!
    
    override func setUp() {
        super.setUp()
        socialGraphManager = SocialGraphManager.shared
        sharingManager = SocialSharingManager.shared
        leaderboardManager = LeaderboardManager.shared
    }
    
    override func tearDown() {
        socialGraphManager = nil
        sharingManager = nil
        leaderboardManager = nil
        super.tearDown()
    }
    
    // MARK: - Social Graph Tests
    
    func testFollowUser() throws {
        let context = PersistenceController.preview.container.viewContext
        
        let follower = User(context: context)
        follower.id = UUID()
        follower.username = "Follower"
        
        let following = User(context: context)
        following.id = UUID()
        following.username = "Following"
        
        try socialGraphManager.follow(user: following, follower: follower)
        
        XCTAssertTrue(socialGraphManager.isFollowing(userID: following.id!, followerID: follower.id!))
    }
    
    func testCannotFollowSelf() throws {
        let context = PersistenceController.preview.container.viewContext
        
        let user = User(context: context)
        user.id = UUID()
        user.username = "TestUser"
        
        XCTAssertThrowsError(try socialGraphManager.follow(user: user, follower: user)) { error in
            XCTAssertEqual(error as? SocialGraphError, .cannotFollowSelf)
        }
    }
    
    func testUnfollowUser() throws {
        let context = PersistenceController.preview.container.viewContext
        
        let follower = User(context: context)
        follower.id = UUID()
        follower.username = "Follower"
        
        let following = User(context: context)
        following.id = UUID()
        following.username = "Following"
        
        try socialGraphManager.follow(user: following, follower: follower)
        XCTAssertTrue(socialGraphManager.isFollowing(userID: following.id!, followerID: follower.id!))
        
        try socialGraphManager.unfollow(user: following, follower: follower)
        XCTAssertFalse(socialGraphManager.isFollowing(userID: following.id!, followerID: follower.id!))
    }
    
    func testBlockUser() throws {
        let context = PersistenceController.preview.container.viewContext
        
        let blocker = User(context: context)
        blocker.id = UUID()
        blocker.username = "Blocker"
        
        let blocked = User(context: context)
        blocked.id = UUID()
        blocked.username = "Blocked"
        
        try socialGraphManager.block(user: blocked, blocker: blocker)
        
        XCTAssertTrue(socialGraphManager.isBlocked(userID: blocked.id!, blockerID: blocker.id!))
    }
    
    func testUnblockUser() throws {
        let context = PersistenceController.preview.container.viewContext
        
        let blocker = User(context: context)
        blocker.id = UUID()
        blocker.username = "Blocker"
        
        let blocked = User(context: context)
        blocked.id = UUID()
        blocked.username = "Blocked"
        
        try socialGraphManager.block(user: blocked, blocker: blocker)
        XCTAssertTrue(socialGraphManager.isBlocked(userID: blocked.id!, blockerID: blocker.id!))
        
        try socialGraphManager.unblock(user: blocked, blocker: blocker)
        XCTAssertFalse(socialGraphManager.isBlocked(userID: blocked.id!, blockerID: blocker.id!))
    }
    
    func testCannotFollowBlockedUser() throws {
        let context = PersistenceController.preview.container.viewContext
        
        let user = User(context: context)
        user.id = UUID()
        user.username = "User"
        
        let blockedUser = User(context: context)
        blockedUser.id = UUID()
        blockedUser.username = "BlockedUser"
        
        try socialGraphManager.block(user: blockedUser, blocker: user)
        
        XCTAssertThrowsError(try socialGraphManager.follow(user: blockedUser, follower: user)) { error in
            XCTAssertEqual(error as? SocialGraphError, .blocked)
        }
    }
    
    // MARK: - Social Sharing Tests
    
    func testCreateShareContentFromPhrase() {
        let context = PersistenceController.preview.container.viewContext
        
        let phrase = CommunityPhrase(context: context)
        phrase.humanText = "Hello"
        phrase.dogTranslation = "Woof woof"
        phrase.qualityScore = 0.9
        
        let contributor = User(context: context)
        contributor.username = "Contributor"
        phrase.submitter = contributor
        
        let content = sharingManager.createShareContent(from: phrase)
        
        XCTAssertEqual(content.humanText, "Hello")
        XCTAssertEqual(content.dogTranslation, "Woof woof")
        XCTAssertEqual(content.contributorName, "Contributor")
        XCTAssertTrue(content.shareText.contains("Hello"))
    }
    
    func testShareContentWithTranslation() {
        let content = sharingManager.createShareContent(humanText: "Good morning", dogTranslation: "Woof!")
        
        XCTAssertEqual(content.humanText, "Good morning")
        XCTAssertEqual(content.dogTranslation, "Woof!")
        XCTAssertNil(content.contributorName)
    }
    
    // MARK: - Leaderboard Tests
    
    func testLeaderboardEntryRanking() {
        leaderboardManager.selectedPeriod = .weekly
        leaderboardManager.refresh()
        
        let entries = leaderboardManager.entries
        
        if entries.count > 1 {
            for i in 1..<entries.count {
                XCTAssertLessThanOrEqual(entries[i-1].score, entries[i].score)
            }
        }
    }
    
    func testLeaderboardPeriods() {
        for period in LeaderboardPeriod.allCases {
            leaderboardManager.selectedPeriod = period
            XCTAssertEqual(leaderboardManager.selectedPeriod, period)
        }
    }
    
    func testLeaderboardTopEntries() {
        leaderboardManager.refresh()
        
        let topEntries = leaderboardManager.getTopEntries(count: 5)
        
        XCTAssertLessThanOrEqual(topEntries.count, 5)
    }
    
    func testLeaderboardCaching() {
        leaderboardManager.refresh()
        
        XCTAssertNotNil(leaderboardManager.lastUpdated)
    }
}
