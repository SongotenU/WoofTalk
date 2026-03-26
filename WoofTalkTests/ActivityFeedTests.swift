// MARK: - ActivityFeedTests

import XCTest
@testable import WoofTalk

final class ActivityFeedTests: XCTestCase {
    
    var activityManager: ActivityEventManager!
    var notificationManager: NotificationManager!
    
    override func setUp() {
        super.setUp()
        activityManager = ActivityEventManager.shared
        notificationManager = NotificationManager.shared
    }
    
    override func tearDown() {
        activityManager.clearAll()
        activityManager = nil
        notificationManager = nil
        super.tearDown()
    }
    
    // MARK: - Activity Event Tests
    
    func testPostNewFollowerEvent() {
        let context = PersistenceController.preview.container.viewContext
        
        let targetUser = User(context: context)
        targetUser.id = UUID()
        targetUser.username = "TargetUser"
        
        let fromUser = User(context: context)
        fromUser.id = UUID()
        fromUser.username = "FromUser"
        
        let event = ActivityEventFactory.newFollower(targetUser: targetUser, fromUser: fromUser)
        
        XCTAssertEqual(event.type, .newFollower)
        XCTAssertEqual(event.actorName, "FromUser")
        XCTAssertEqual(event.targetUserName, "TargetUser")
    }
    
    func testPostContributionApprovedEvent() {
        let context = PersistenceController.preview.container.viewContext
        
        let user = User(context: context)
        user.id = UUID()
        user.username = "Contributor"
        
        let contribution = Contribution(context: context)
        contribution.id = UUID()
        contribution.humanText = "Test"
        contribution.dogTranslation = "Woof"
        contribution.qualityScore = 0.85
        contribution.user = user
        
        let event = ActivityEventFactory.contributionApproved(contribution: contribution)
        
        XCTAssertEqual(event.type, .contributionApproved)
        XCTAssertEqual(event.metadata?["quality_score"], "0.85")
    }
    
    func testPostLeaderboardChangeEvent() {
        let context = PersistenceController.preview.container.viewContext
        
        let user = User(context: context)
        user.id = UUID()
        user.username = "TopContributor"
        
        let event = ActivityEventFactory.leaderboardChange(user: user, newRank: 5, previousRank: 10)
        
        XCTAssertEqual(event.type, .leaderboardChange)
        XCTAssertEqual(event.metadata?["new_rank"], "5")
        XCTAssertEqual(event.metadata?["previous_rank"], "10")
    }
    
    func testPostMilestoneEvent() {
        let context = PersistenceController.preview.container.viewContext
        
        let user = User(context: context)
        user.id = UUID()
        user.username = "MilestoneUser"
        
        let event = ActivityEventFactory.milestoneReached(user: user, milestone: "100 contributions")
        
        XCTAssertEqual(event.type, .milestoneReached)
        XCTAssertEqual(event.metadata?["milestone"], "100 contributions")
    }
    
    // MARK: - Activity Feed Tests
    
    func testActivityManagerPostEvent() {
        let event = ActivityEvent(type: .newFollower)
        
        activityManager.post(event)
        
        XCTAssertTrue(activityManager.events.contains { $0.id == event.id })
    }
    
    func testGetEventsForUser() {
        let context = PersistenceController.preview.container.viewContext
        
        let targetUser = User(context: context)
        targetUser.id = UUID()
        targetUser.username = "TargetUser"
        
        let fromUser = User(context: context)
        fromUser.id = UUID()
        fromUser.username = "FromUser"
        
        let event = ActivityEventFactory.newFollower(targetUser: targetUser, fromUser: fromUser)
        activityManager.post(event)
        
        let userEvents = activityManager.getEvents(for: targetUser.id!)
        
        XCTAssertTrue(userEvents.contains { $0.id == event.id })
    }
    
    func testGetRecentEvents() {
        for i in 0..<25 {
            let event = ActivityEvent(type: .contributionApproved)
            activityManager.post(event)
        }
        
        let recentEvents = activityManager.getRecentEvents(limit: 20)
        
        XCTAssertEqual(recentEvents.count, 20)
    }
    
    func testGetEventsByType() {
        activityManager.post(ActivityEvent(type: .newFollower))
        activityManager.post(ActivityEvent(type: .newFollower))
        activityManager.post(ActivityEvent(type: .leaderboardChange))
        
        let followerEvents = activityManager.getEvents(byType: .newFollower)
        
        XCTAssertEqual(followerEvents.count, 2)
    }
    
    func testClearAllEvents() {
        activityManager.post(ActivityEvent(type: .newFollower))
        activityManager.post(ActivityEvent(type: .contributionApproved))
        
        activityManager.clearAll()
        
        XCTAssertTrue(activityManager.events.isEmpty)
    }
    
    func testClearOldEvents() {
        let oldEvent = ActivityEvent(type: .newFollower, timestamp: Date().addingTimeInterval(-86400 * 7))
        let newEvent = ActivityEvent(type: .contributionApproved, timestamp: Date())
        
        activityManager.post(oldEvent)
        activityManager.post(newEvent)
        
        let oneDayAgo = Date().addingTimeInterval(-86400)
        activityManager.clearEvents(olderThan: oneDayAgo)
        
        XCTAssertFalse(activityManager.events.contains { $0.id == oldEvent.id })
        XCTAssertTrue(activityManager.events.contains { $0.id == newEvent.id })
    }
    
    // MARK: - Notification Manager Tests
    
    func testNotificationAuthorizationStatus() {
        notificationManager.checkAuthorizationStatus()
        
        XCTAssertNotNil(notificationManager.isAuthorized)
    }
    
    func testBadgeCountManagement() {
        notificationManager.updateBadgeCount(5)
        
        notificationManager.clearBadge()
    }
}
