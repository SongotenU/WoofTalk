// MARK: - CommunityPhraseManager

import Foundation
import CoreData

/// Errors that can occur during community phrase creation
enum CommunityPhraseError: LocalizedError {
    case duplicatePhrase
    case coreDataSaveFailed
    case invalidContribution

    var errorDescription: String? {
        switch self {
        case .duplicatePhrase:
            return "This community phrase already exists."
        case .coreDataSaveFailed:
            return "Failed to save community phrase to local storage"
        case .invalidContribution:
            return "Contribution is invalid or already processed"
        }
    }
}

/// Manages community phrase creation from approved contributions
final class CommunityPhraseManager {

    private let coreDataContext: NSManagedObjectContext

    init(coreDataContext: NSManagedObjectContext) {
        self.coreDataContext = coreDataContext
    }

    /// Creates a community phrase from an approved contribution
    func createCommunityPhrase(from contribution: Contribution) throws {
        guard contribution.status == ContributionStatus.approved.rawValue else {
            throw CommunityPhraseError.invalidContribution
        }

        if let existingPhrase = CommunityPhrase.findExisting(
            for: contribution.humanText ?? "",
            direction: "en-dog",
            context: coreDataContext
        ) {
            contribution.displayStatus = .duplicate
            contribution.validationNotes = "Duplicate of existing community phrase"
            try coreDataContext.save()
            throw CommunityPhraseError.duplicatePhrase
        }

        let communityPhrase = CommunityPhrase(context: coreDataContext)
        communityPhrase.id = UUID()
        communityPhrase.humanText = contribution.humanText
        communityPhrase.dogTranslation = contribution.dogTranslation
        communityPhrase.qualityScore = contribution.qualityScore
        communityPhrase.timestamp = Date()
        communityPhrase.submitter = contribution.user
        communityPhrase.direction = "en-dog"

        contribution.displayStatus = .processed
        contribution.validationNotes = "Converted to community phrase"

        do {
            try coreDataContext.save()
        } catch {
            coreDataContext.rollback()
            throw CommunityPhraseError.coreDataSaveFailed
        }
    }
}
