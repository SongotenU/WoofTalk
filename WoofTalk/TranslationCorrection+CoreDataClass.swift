// MARK: - TranslationCorrection Core Data Entity

import Foundation
import CoreData

/// Core Data entity for storing user translation corrections
@objc(TranslationCorrection)
public class TranslationCorrection: NSManagedObject, @unchecked Sendable {

    @NSManaged public var id: UUID?
    @NSManaged public var originalInput: String?
    @NSManaged public var originalTranslation: String?
    @NSManaged public var correctedTranslation: String?
    @NSManaged public var direction: String?
    @NSManaged public var confidence: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var usedInTraining: Bool
}

extension TranslationCorrection {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TranslationCorrection> {
        return NSFetchRequest<TranslationCorrection>(entityName: "TranslationCorrection")
    }
}
