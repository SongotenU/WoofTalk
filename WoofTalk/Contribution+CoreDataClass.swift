// MARK: - Contribution Core Data Entity

import Foundation
import CoreData

/// Core Data entity for contributions
@objc(Contribution)
public class Contribution: NSManagedObject {
    
    @NSManaged public var humanText: String?
    @NSManaged public var dogTranslation: String?
    @NSManaged public var qualityScore: Double
    @NSManaged public var status: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var validationNotes: String?
    @NSManaged public var validationWarnings: [String]
    @NSManaged public var user: User?
    @NSManaged public var id: UUID?
    
    // Transient properties (not persisted)
    @transient public var displayStatus: ContributionStatus {
        get { return ContributionStatus(rawValue: status ?? "validated") ?? .validated }
        set { status = newValue.rawValue }
    }
}