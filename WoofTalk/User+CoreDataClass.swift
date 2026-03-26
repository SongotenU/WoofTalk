// MARK: - User Core Data Entity

import Foundation
import CoreData

/// Core Data entity for users
@objc(User)
public class User: NSManagedObject {
    
    @NSManaged public var id: UUID?
    @NSManaged public var username: String?
    @NSManaged public var email: String?
    @NSManaged public var isModerator: Bool
    @NSManaged public var contributions: Set<Contribution>?
}