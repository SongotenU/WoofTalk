import Foundation
import CoreData

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

struct ActivityEvent: Identifiable, Codable {
    let id: UUID
    let type: ActivityEventType
    let timestamp: Date
    let actorID: UUID?
    let actorName: String?
    let targetUserID: UUID?
    let targetUserName: String?
    let metadata: [String: String]?

    init(id: UUID = UUID(), type: ActivityEventType, timestamp: Date = Date(),
         actorID: UUID? = nil, actorName: String? = nil,
         targetUserID: UUID? = nil, targetUserName: String? = nil,
         metadata: [String: String]? = nil) {
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

final class ActivityEventManager {
    static let shared = ActivityEventManager(context: PersistenceController.shared.container.viewContext)
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func postEvent(_ event: ActivityEvent) throws {
        let entity = ActivityEventEntity(context: context)
        entity.id = event.id
        entity.type = event.type.rawValue
        entity.timestamp = event.timestamp
        entity.actorID = event.actorID?.uuidString
        entity.actorName = event.actorName
        entity.targetUserID = event.targetUserID?.uuidString
        entity.targetUserName = event.targetUserName
        entity.metadata = event.metadata?.jsonString
        try context.save()
    }

    func fetchEvents(for userID: String? = nil, limit: Int = 50) throws -> [ActivityEvent] {
        let request: NSFetchRequest<ActivityEventEntity> = ActivityEventEntity.fetchRequest()
        if let userID = userID {
            request.predicate = NSPredicate(format: "targetUserID == %@ OR actorID == %@", userID, userID)
        }
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = limit
        return try context.fetch(request).compactMap { $0.toActivityEvent() }
    }

    func deleteEvent(_ event: ActivityEvent) throws {
        let request: NSFetchRequest<ActivityEventEntity> = ActivityEventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
        request.fetchLimit = 1
        if let entity = try context.fetch(request).first {
            context.delete(entity)
            try context.save()
        }
    }

    func clearAllEvents() throws {
        let request: NSFetchRequest<ActivityEventEntity> = ActivityEventEntity.fetchRequest()
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }
}

extension Dictionary where Key == String, Value == String {
    var jsonString: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func from(jsonString: String?) -> [String: String]? {
        guard let data = jsonString?.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return nil }
        return dict
    }
}

@objc(ActivityEventEntity)
public class ActivityEventEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var actorID: String?
    @NSManaged public var actorName: String?
    @NSManaged public var targetUserID: String?
    @NSManaged public var targetUserName: String?
    @NSManaged public var metadata: String?

    func toActivityEvent() -> ActivityEvent? {
        guard let id = id, let typeRaw = type, let type = ActivityEventType(rawValue: typeRaw), let timestamp = timestamp else {
            return nil
        }
        return ActivityEvent(
            id: id, type: type, timestamp: timestamp,
            actorID: actorID.flatMap { UUID(uuidString: $0) },
            actorName: actorName,
            targetUserID: targetUserID.flatMap { UUID(uuidString: $0) },
            targetUserName: targetUserName,
            metadata: Dictionary.from(jsonString: metadata)
        )
    }
}

extension ActivityEventEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityEventEntity> {
        return NSFetchRequest<ActivityEventEntity>(entityName: "ActivityEventEntity")
    }
}
