// MARK: - CommunityPhraseManager

import Foundation
import CoreData

/// Errors that can occur during community phrase creation
enum CommunityPhraseError: LocalizedError {
    case duplicatePhrase
    case coreDataSaveFailed
    case invalidContribution
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .duplicatePhrase:
            return "This community phrase already exists."
        case .coreDataSaveFailed:
            return "Failed to save community phrase to local storage"
        case .invalidContribution:
            return "Contribution is invalid or already processed"
        case .unknown:
            return "An unknown error occurred during community phrase creation"
        }
    }
}

/// Manages community phrase creation from approved contributions
final class CommunityPhraseManager {
    
    // MARK: - Dependencies
    
    private let coreDataContext: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(coreDataContext: NSManagedObjectContext) {
        self.coreDataContext = coreDataContext
    }
    
    // MARK: - Public API
    
    /// Creates a community phrase from an approved contribution
    /// - Parameter contribution: The approved contribution to convert
    /// - Throws: CommunityPhraseError if creation fails
    func createCommunityPhrase(from contribution: Contribution) throws {
        // Validate contribution status
        guard contribution.status == ContributionStatus.approved.rawValue else {
            throw CommunityPhraseError.invalidContribution
        }
        
        // Check for existing duplicate phrase
        if let existingPhrase = findExistingCommunityPhrase(for: contribution.humanText ?? "", direction: "en-dog") {
            // Update contribution to reference existing phrase instead of creating duplicate
            contribution.displayStatus = .duplicate
            contribution.validationNotes = "Duplicate of existing community phrase"
            try coreDataContext.save()
            throw CommunityPhraseError.duplicatePhrase
        }
        
        // Create new community phrase entity
        let communityPhrase = CommunityPhrase(context: coreDataContext)
        communityPhrase.id = UUID()
        communityPhrase.humanText = contribution.humanText
        communityPhrase.dogTranslation = contribution.dogTranslation
        communityPhrase.qualityScore = contribution.qualityScore
        communityPhrase.timestamp = Date()
        communityPhrase.submitter = contribution.user
        communityPhrase.direction = "en-dog"
        
        // Update contribution status to processed
        contribution.displayStatus = .processed
        contribution.validationNotes = "Converted to community phrase"
        
        // Save to Core Data
        do {
            try coreDataContext.save()
        } catch {
            // Rollback changes if save fails
            coreDataContext.rollback()
            throw CommunityPhraseError.coreDataSaveFailed
        }
    }
    
    /// Finds an existing community phrase by human text and direction
    /// - Parameters:
    ///   - humanText: The human text to search for
    ///   - direction: The translation direction (e.g., "en-dog")
    /// - Returns: The existing community phrase if found, nil otherwise
    func findExistingCommunityPhrase(for humanText: String, direction: String) -> CommunityPhrase? {
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "humanText == %@ AND direction == %@", humanText, direction)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try coreDataContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error finding existing community phrase: \(error)")
            return nil
        }
    }
    
    /// Gets all community phrases sorted by quality score
    /// - Returns: Array of community phrases sorted by quality
    func getAllCommunityPhrases() -> [CommunityPhrase] {
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "qualityScore", ascending: false)]
        
        do {
            return try coreDataContext.fetch(fetchRequest)
        } catch {
            print("Error fetching community phrases: \(error)")
            return []
        }
    }
    
    /// Gets community phrases for a specific direction
    /// - Parameter direction: The translation direction to filter by
    /// - Returns: Array of community phrases for the specified direction
    func getCommunityPhrases(for direction: String) -> [CommunityPhrase] {
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "direction == %@", direction)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "qualityScore", ascending: false)]
        
        do {
            return try coreDataContext.fetch(fetchRequest)
        } catch {
            print("Error fetching community phrases for direction \(direction): \(error)")
            return []
        }
    }
}