import Foundation
import CoreData

@objc(CommunityPhrase)
public class CommunityPhrase: NSManagedObject, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var humanText: String?
    @NSManaged public var dogTranslation: String?
    @NSManaged public var qualityScore: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var submitter: User?
    @NSManaged public var direction: String?
    @NSManaged public var usageCount: Int64
    @NSManaged public var lastUsed: Date?
    @NSManaged public var photoData: Data?
    @NSManaged public var reactions: [String: Int]?

    private var ageComponents: DateComponents? {
        guard let timestamp else { return nil }
        return Calendar.current.dateComponents([.day, .hour, .minute], from: timestamp, to: Date())
    }

    @transient public var ageInDays: Int { ageComponents?.day ?? 0 }
    @transient public var ageInHours: Int { ageComponents?.hour ?? 0 }
    @transient public var ageInMinutes: Int { ageComponents?.minute ?? 0 }

    static func create(humanText: String, dogTranslation: String, qualityScore: Double, direction: String, submitter: User, context: NSManagedObjectContext) -> CommunityPhrase {
        let phrase = CommunityPhrase(context: context)
        phrase.id = UUID()
        phrase.humanText = humanText
        phrase.dogTranslation = dogTranslation
        phrase.qualityScore = qualityScore
        phrase.timestamp = Date()
        phrase.submitter = submitter
        phrase.direction = direction
        phrase.usageCount = 0
        return phrase
    }

    static func getAllSortedByQuality(context: NSManagedObjectContext) -> [CommunityPhrase] {
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "qualityScore", ascending: false)]
        return (try? context.fetch(fetchRequest)) ?? []
    }

    func incrementUsageCount(context: NSManagedObjectContext) throws {
        usageCount += 1
        lastUsed = Date()
        try context.save()
    }

    func update(dogTranslation: String, qualityScore: Double, context: NSManagedObjectContext) throws {
        self.dogTranslation = dogTranslation
        self.qualityScore = qualityScore
        try context.save()
    }

    func delete(context: NSManagedObjectContext) throws {
        context.delete(self)
        try context.save()
    }

    func addReaction(_ emoji: String, context: NSManagedObjectContext) throws {
        var current = reactions ?? [:]
        current[emoji, default: 0] += 1
        reactions = current
        try context.save()
    }

    func removeReaction(_ emoji: String, context: NSManagedObjectContext) throws {
        var current = reactions ?? [:]
        guard let count = current[emoji], count > 0 else { return }
        if count == 1 {
            current.removeValue(forKey: emoji)
        } else {
            current[emoji] = count - 1
        }
        reactions = current
        try context.save()
    }

    var topReactions: [(emoji: String, count: Int)] {
        guard let reactions = reactions else { return [] }
        return reactions.map { ($0.key, $0.value) }.sorted { $0.count > $1.count }.prefix(3).map { ($0.emoji, $0.count) }
    }

    var photoImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
}