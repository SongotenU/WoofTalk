// MARK: - ActivityEventManager

import Foundation
import CoreData
import Combine

/// Types of activity events
enum ActivityEventType: String, Codable, CaseIterable {
    case newFollower = "new_follower"
    case contributionApproved = "contribution_approved"
    case contributionRejected = "contribution_rejected"
    case leaderboardChange = "leaderboard_change"
    case phraseFeatured = "phrase_featured"
    case milestoneReached = "milestone_reached"
    
    var icon: String {
        switch self {
        case .newFollower: return "person.badge.plus"
        case .contributionApproved: return "checkmark.circle.fill"
        case .contributionRejected: return "xmark.circle.fill"
        case .leaderboardChange: return "chart.bar.fill"
        case .phraseFeatured: return "star.fill"
        case .milestoneReached: return "flag.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .newFollower: return "New Follower"
        case .contributionApproved: return "Contribution Approved"
        case .contributionRejected: return "Contribution Rejected"
        case .leaderboardChange: return "Leaderboard Update"
        case .phraseFeatured: return "Phrase Featured"
        case .milestoneReached: return "Milestone Reached"
        }
    }
}

/// Activity event data
struct ActivityEvent: Identifiable, Codable {
    let id: UUID
    let type: ActivityEventType
    let timestamp: Date
    let actorID: UUID?
    let actorName: String?
    let targetUserID: UUID?
    let targetUserName: String?
    let metadata: [String: String]?
    
    init(
        id: UUID = UUID(),
        type: ActivityEventType,
        timestamp: Date = Date(),
        actorID: UUID? = nil,
        actorName: String? = nil,
        targetUserID: UUID? = nil,
        targetUserName: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.actorID = actorID
        self.actorName = actorName
        self.targetUserID = targetUserID
        self.targetUserName = targetUserName
        self.metadata = metadata
    }
}

/// Factory for creating activity events
enum ActivityEventFactory {
    static func newFollower(targetUser: User, fromUser: User) -> ActivityEvent {
        return ActivityEvent(
            type: .newFollower,
            actorID: fromUser.id,
            actorName: fromUser.username,
            targetUserID: targetUser.id,
            targetUserName: targetUser.username
        )
    }
    
    static func contributionApproved(contribution: Contribution) -> ActivityEvent {
        return ActivityEvent(
            type: .contributionApproved,
            actorID: contribution.user?.id,
            actorName: contribution.user?.username,
            metadata: ["quality_score": String(contribution.qualityScore)]
        )
    }
    
    static func leaderboardChange(user: User, newRank: Int, previousRank: Int) -> ActivityEvent {
        return ActivityEvent(
            type: .leaderboardChange,
            actorID: user.id,
            actorName: user.username,
            metadata: [
                "new_rank": String(newRank),
                "previous_rank": String(previousRank)
            ]
        )
    }
    
    static func milestoneReached(user: User, milestone: String) -> ActivityEvent {
        return ActivityEvent(
            type: .milestoneReached,
            actorID: user.id,
            actorName: user.username,
            metadata: ["milestone": milestone]
        )
    }
}

/// Manages activity feed events
final class ActivityEventManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var events: [ActivityEvent] = []
    @Published private(set) var isLoading = false
    
    private let maxEvents = 100
    private let storageKey = "activity_events"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    
    static let shared = ActivityEventManager()
    
    // MARK: - Initialization
    
    private init() {
        loadEvents()
    }
    
    // MARK: - Public API
    
    /// Posts a new activity event
    /// - Parameter event: The event to post
    func post(_ event: ActivityEvent) {
        events.insert(event, at: 0)
        
        if events.count > maxEvents {
            events = Array(events.prefix(maxEvents))
        }
        
        saveEvents()
        
        // Notify observers
        NotificationCenter.default.post(
            name: .activityEventPosted,
            object: nil,
            userInfo: ["event": event]
        )
    }
    
    /// Posts an event with factory
    /// - Parameters:
    ///   - type: The type of event
    ///   - builder: Builder closure for event properties
    func post(type: ActivityEventType, builder: ((inout ActivityEvent) -> Void)? = nil) {
        var event = ActivityEvent(type: type)
        builder?(&event)
        post(event)
    }
    
    /// Gets events for a specific user
    /// - Parameter userID: The user's ID
    /// - Returns: Filtered events
    func getEvents(for userID: UUID) -> [ActivityEvent] {
        return events.filter { event in
            event.targetUserID == userID || event.actorID == userID
        }
    }
    
    /// Gets recent events
    /// - Parameter limit: Maximum number of events to return
    /// - Returns: Recent events
    func getRecentEvents(limit: Int = 20) -> [ActivityEvent] {
        return Array(events.prefix(limit))
    }
    
    /// Gets events by type
    /// - Parameter type: The event type
    /// - Returns: Filtered events
    func getEvents(byType type: ActivityEventType) -> [ActivityEvent] {
        return events.filter { $0.type == type }
    }
    
    /// Clears all events
    func clearAll() {
        events.removeAll()
        saveEvents()
    }
    
    /// Clears events older than a date
    /// - Parameter date: The cutoff date
    func clearEvents(olderThan date: Date) {
        events.removeAll { $0.timestamp < date }
        saveEvents()
    }
    
    // MARK: - Private Methods
    
    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ActivityEvent].self, from: data) else {
            return
        }
        events = decoded
    }
    
    private func saveEvents() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let activityEventPosted = Notification.Name("activityEventPosted")
    static let newFollowerReceived = Notification.Name("newFollowerReceived")
    static let leaderboardRankChanged = Notification.Name("leaderboardRankChanged")
}
