import Foundation
import CoreData

extension Translation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Translation> {
        return NSFetchRequest<Translation>(entityName: "Translation")
    }

    @NSManaged public var originalText: String
    @NSManaged public var translatedText: String
    @NSManaged public var modeUsed: String?
    @NSManaged public var qualityScore: Double
    @NSManaged public var modelVersion: String?
    @NSManaged public var inferenceTime: Double
    @NSManaged public var timestamp: Date
    @NSManaged public var id: UUID
}
