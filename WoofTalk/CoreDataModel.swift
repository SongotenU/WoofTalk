import Foundation
import CoreData

@MainActor
enum ContributionStatus: String, CaseIterable, Codable, Sendable {
    case validated = "validated"
    case pending = "pending"
    case submitted = "submitted"
    case approved = "approved"
    case rejected = "rejected"
    case failed = "failed"

    var displayText: String { rawValue.capitalized }
}

@MainActor
struct CoreDataModel {
    static func createContribution(
        in context: NSManagedObjectContext,
        humanText: String,
        dogTranslation: String,
        qualityScore: Double,
        status: ContributionStatus,
        timestamp: Date,
        validationNotes: String? = nil,
        validationWarnings: [String] = [],
        user: User? = nil
    ) -> Contribution {
        let contribution = Contribution(context: context)
        contribution.id = UUID()
        contribution.humanText = humanText
        contribution.dogTranslation = dogTranslation
        contribution.qualityScore = qualityScore
        contribution.status = status.rawValue
        contribution.timestamp = timestamp
        contribution.validationNotes = validationNotes
        contribution.validationWarnings = validationWarnings
        contribution.user = user
        return contribution
    }

    static func createUser(
        in context: NSManagedObjectContext,
        username: String,
        email: String,
        isModerator: Bool = false
    ) -> User {
        let user = User(context: context)
        user.id = UUID()
        user.username = username
        user.email = email
        user.isModerator = isModerator
        return user
    }
}
