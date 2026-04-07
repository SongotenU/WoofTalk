// MARK: - Core Data Model Definition

import Foundation
import CoreData

/// Core Data model for the WoofTalk app
struct CoreDataModel {
    
    // MARK: - Entity Names
    
    static let contributionEntityName = "Contribution"
    static let userEntityName = "User"
    
    // MARK: - Contribution Entity Properties
    
    enum ContributionAttributes: String {
        case humanText = "humanText"
        case dogTranslation = "dogTranslation"
        case qualityScore = "qualityScore"
        case status = "status"
        case timestamp = "timestamp"
        case validationNotes = "validationNotes"
        case validationWarnings = "validationWarnings"
        case user = "user"
        case id = "id"
    }
    
    // MARK: - Contribution Status
    
    enum ContributionStatus: String, CaseIterable, Codable {
        case validated = "validated"
        case pending = "pending"
        case submitted = "submitted"
        case approved = "approved"
        case rejected = "rejected"
        case failed = "failed"
        
        var displayText: String {
            switch self {
            case .validated: return "Validated"
            case .pending: return "Pending"
            case .submitted: return "Submitted"
            case .approved: return "Approved"
            case .rejected: return "Rejected"
            case .failed: return "Failed"
            }
        }
    }
    
    // MARK: - User Entity Properties
    
    enum UserAttributes: String {
        case id = "id"
        case username = "username"
        case email = "email"
        case isModerator = "isModerator"
        case contributions = "contributions"
    }
    
    // MARK: - Core Data Helper Methods
    
    /// Creates a Contribution entity in the given context
    static func createContributionEntity(
        in context: NSManagedObjectContext,
        humanText: String,
        dogTranslation: String,
        qualityScore: Double,
        status: ContributionStatus,
        timestamp: Date,
        validationNotes: String? = nil,
        validationWarnings: [String] = [],
        user: User? = nil
    ) throws -> Contribution {
        let contribution = Contribution(context: context)
        
        contribution.humanText = humanText
        contribution.dogTranslation = dogTranslation
        contribution.qualityScore = qualityScore
        contribution.status = status.rawValue
        contribution.timestamp = timestamp
        contribution.validationNotes = validationNotes
        contribution.validationWarnings = validationWarnings
        contribution.user = user
        contribution.id = UUID()
        
        return contribution
    }
    
    /// Creates a User entity in the given context
    static func createUserEntity(
        in context: NSManagedObjectContext,
        username: String,
        email: String,
        isModerator: Bool = false
    ) throws -> User {
        let user = User(context: context)
        
        user.id = UUID()
        user.username = username
        user.email = email
        user.isModerator = isModerator
        
        return user
    }
}