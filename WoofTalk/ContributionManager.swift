// MARK: - ContributionManager

import Foundation
import CoreData

/// Errors that can occur during contribution submission
enum ContributionError: LocalizedError {
    case validationFailed(errors: [ValidationError])
    case coreDataSaveFailed
    case networkUnavailable
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Validation failed: " + errors.map { $0.errorDescription ?? "Unknown error" }.joined(separator: ", ")
        case .coreDataSaveFailed:
            return "Failed to save contribution to local storage"
        case .networkUnavailable:
            return "Network is unavailable. Contribution will be saved offline."
        case .unknown:
            return "An unknown error occurred during contribution submission"
        }
    }
}

/// Manages contribution creation, validation, and submission
final class ContributionManager {
    
    // MARK: - Dependencies
    
    private let validationService = ContributionValidationService()
    private let coreDataContext: NSManagedObjectContext
    private let contributionSyncManager: ContributionSyncManager
    
    // MARK: - Initialization
    
    init(coreDataContext: NSManagedObjectContext, contributionSyncManager: ContributionSyncManager) {
        self.coreDataContext = coreDataContext
        self.contributionSyncManager = contributionSyncManager
    }
    
    // MARK: - Public API
    
    /// Submits a translation for contribution after validation
    /// - Parameters:
    ///   - translationRecord: The translation to submit
    ///   - completion: Completion handler with result
    func submitTranslation(_ translationRecord: TranslationRecord, completion: @escaping (Result<Void, ContributionError>) -> Void) {
        // Step 1: Validate the translation
        let validationResult = validationService.validate(translationRecord: translationRecord)
        
        switch validationResult {
        case .invalid(let errors):
            // Validation failed - return errors
            completion(.failure(.validationFailed(errors: errors)))
            return
            
        case .warning(let qualityScore, let warnings):
            // Validation passed with warnings - proceed but show warnings
            handleValidatedTranslation(
                translationRecord,
                qualityScore: qualityScore,
                warnings: warnings,
                completion: completion
            )
            
        case .valid(let qualityScore):
            // Validation passed - proceed with submission
            handleValidatedTranslation(
                translationRecord,
                qualityScore: qualityScore,
                warnings: [],
                completion: completion
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles the validated translation by creating a contribution entity
    private func handleValidatedTranslation(
        _ translationRecord: TranslationRecord,
        qualityScore: Double,
        warnings: [ValidationWarning],
        completion: @escaping (Result<Void, ContributionError>) -> Void
    ) {
        // Check network availability
        let isNetworkAvailable = contributionSyncManager.isNetworkAvailable()
        
        // Create contribution entity
        do {
            let contribution = try createContributionEntity(
                translationRecord,
                qualityScore: qualityScore,
                warnings: warnings
            )
            
            // Save to Core Data
            try coreDataContext.save()
            
            // Handle offline/online submission
            if isNetworkAvailable {
                // Online - submit immediately
                contributionSyncManager.submitContribution(contribution) { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success():
                        // Successfully submitted - update contribution status
                        contribution.status = .submitted
                        try? self.coreDataContext.save()
                        completion(.success(()))
                        
                    case .failure(let error):
                        // Network error - mark as pending for retry
                        contribution.status = .pending
                        try? self.coreDataContext.save()
                        completion(.failure(.networkUnavailable))
                    }
                }
            } else {
                // Offline - mark as pending and add to sync queue
                contribution.status = .pending
                try coreDataContext.save()
                
                // Add to offline queue for later sync
                contributionSyncManager.queueContributionForSync(contribution)
                
                completion(.failure(.networkUnavailable))
            }
            
        } catch {
            // Core Data save failed
            completion(.failure(.coreDataSaveFailed))
        }
    }
    
    /// Creates a Contribution entity from translation record
    private func createContributionEntity(
        _ translationRecord: TranslationRecord,
        qualityScore: Double,
        warnings: [ValidationWarning]
    ) throws -> Contribution {
        // Create new contribution
        let contribution = Contribution(context: coreDataContext)
        
        // Set basic properties
        contribution.humanText = translationRecord.humanText
        contribution.dogTranslation = translationRecord.dogTranslation
        contribution.qualityScore = qualityScore
        contribution.status = .validated
        contribution.timestamp = Date()
        contribution.validationNotes = formatValidationNotes(warnings)
        
        // Set validation warnings
        contribution.validationWarnings = warnings.map { $0.errorDescription ?? "Unknown warning" }
        
        // Link to current user if available (optional)
        if let currentUser = getCurrentUser() {
            contribution.user = currentUser
        }
        
        return contribution
    }
    
    /// Formats validation notes from warnings
    private func formatValidationNotes(_ warnings: [ValidationWarning]) -> String {
        return warnings.map { $0.errorDescription ?? "Unknown warning" }.joined(separator: "; ")
    }
    
    /// Gets the current user for contribution attribution
    private func getCurrentUser() -> User? {
        // In a real app, this would fetch from authentication or user manager
        // For now, return nil (anonymous contribution)
        return nil
    }
}

// MARK: - Contribution Entity Extension

extension Contribution {
    /// Convenience initializer for creating contribution from translation record
    convenience init(
        humanText: String,
        dogTranslation: String,
        qualityScore: Double,
        status: ContributionStatus,
        timestamp: Date,
        validationNotes: String? = nil,
        validationWarnings: [String] = [],
        user: User? = nil,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.humanText = humanText
        self.dogTranslation = dogTranslation
        self.qualityScore = qualityScore
        self.status = status
        self.timestamp = timestamp
        self.validationNotes = validationNotes
        self.validationWarnings = validationWarnings
        self.user = user
    }
}

// MARK: - Contribution Status

/// Status of a contribution through its lifecycle
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

// MARK: - Contribution Entity (Core Data)

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