// MARK: - CommunityPhrase

import Foundation
import CoreData

/// Core Data entity for community phrases
@objc(CommunityPhrase)
public class CommunityPhrase: NSManagedObject {
    
    @NSManaged public var id: UUID?
    @NSManaged public var humanText: String?
    @NSManaged public var dogTranslation: String?
    @NSManaged public var qualityScore: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var submitter: User?
    @NSManaged public var direction: String?
    @NSManaged public var usageCount: Int64
    @NSManaged public var lastUsed: Date?
    
    // Transient properties
    @transient public var ageInDays: Int {
        guard let timestamp = timestamp else { return 0 }
        return Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
    }
    
    @transient public var ageInHours: Int {
        guard let timestamp = timestamp else { return 0 }
        return Calendar.current.dateComponents([.hour], from: timestamp, to: Date()).hour ?? 0
    }
    
    @transient public var ageInMinutes: Int {
        guard let timestamp = timestamp else { return 0 }
        return Calendar.current.dateComponents([.minute], from: timestamp, to: Date()).minute ?? 0
    }
    
    @transient public var ageDisplay: String {
        let days = ageInDays
        let hours = ageInHours
        let minutes = ageInMinutes
        
        if days > 0 {
            return "\(days) day\"(s) ago"
        } else if hours > 0 {
            return "\(hours) hour\"(s) ago"
        } else {
            return "\(minutes) minute\"(s) ago"
        }
    }
    
    @transient public var qualityDisplay: String {
        return "Quality: \(Int(qualityScore * 100))%"
    }
    
    @transient public var submitterDisplay: String {
        return submitter?.username ?? "Unknown"
    }
    
    @transient public var directionDisplay: String {
        return direction ?? "Unknown"
    }
    
    /// Gets community phrases sorted by quality score
    /// - Parameter context: The Core Data context
    /// - Returns: Array of community phrases sorted by quality
    static func getAllSortedByQuality(context: NSManagedObjectContext) -> [CommunityPhrase] {
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "qualityScore", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching community phrases: \(error)")
            return []
        }
    }
    
    /// Gets community phrases for a specific direction
    /// - Parameters:
    ///   - direction: The translation direction to filter by
    ///   - context: The Core Data context
    /// - Returns: Array of community phrases for the specified direction
    static func getForDirection(_ direction: String, context: NSManagedObjectContext) -> [CommunityPhrase] {
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "direction == %@", direction)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "qualityScore", ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching community phrases for direction \(direction): \(error)")
            return []
        }
    }
    
    /// Finds community phrase by human text and direction
    /// - Parameters:
    ///   - humanText: The human text to search for
    ///   - direction: The translation direction
    ///   - context: The Core Data context
    /// - Returns: The community phrase if found, nil otherwise
    static func findByHumanText(_ humanText: String, direction: String, context: NSManagedObjectContext) -> CommunityPhrase? {
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "humanText == %@ AND direction == %@", humanText, direction)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error finding community phrase: \(error)")
            return nil
        }
    }
    
    /// Creates a new community phrase
    /// - Parameters:
    ///   - humanText: The human text
    ///   - dogTranslation: The dog translation
    ///   - qualityScore: Quality score
    ///   - direction: Translation direction
    ///   - submitter: User who submitted the contribution
    ///   - context: Core Data context
    /// - Returns: The created community phrase
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
    
    /// Increments usage count for a community phrase
    /// - Parameter context: Core Data context
    /// - Throws: Error if update fails
    func incrementUsageCount(context: NSManagedObjectContext) throws {
        usageCount += 1
        lastUsed = Date()
        
        do {
            try context.save()
        } catch {
            throw error
        }
    }
    
    /// Updates community phrase
    /// - Parameters:
    ///   - dogTranslation: New dog translation
    ///   - qualityScore: New quality score
    ///   - context: Core Data context
    /// - Throws: Error if update fails
    func update(dogTranslation: String, qualityScore: Double, context: NSManagedObjectContext) throws {
        self.dogTranslation = dogTranslation
        self.qualityScore = qualityScore
        
        do {
            try context.save()
        } catch {
            throw error
        }
    }
    
    /// Deletes the community phrase
    /// - Parameter context: Core Data context
    /// - Throws: Error if deletion fails
    func delete(context: NSManagedObjectContext) throws {
        context.delete(self)
        
        do {
            try context.save()
        } catch {
            throw error
        }
    }
}