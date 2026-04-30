import Foundation
import CoreData

final class ContributionManager {

    private let validationService = ContributionValidationService()
    private let coreDataContext: NSManagedObjectContext
    private let contributionSyncManager: ContributionSyncManager

    init(coreDataContext: NSManagedObjectContext, contributionSyncManager: ContributionSyncManager) {
        self.coreDataContext = coreDataContext
        self.contributionSyncManager = contributionSyncManager
    }

    func submitTranslation(_ translationRecord: TranslationRecord, completion: @escaping (Result<Void, ContributionError>) -> Void) {
        let validationResult = validationService.validate(translationRecord: translationRecord)

        switch validationResult {
        case .invalid(let errors):
            completion(.failure(.validationFailed(errors: errors)))

        case .warning(let qualityScore, let warnings):
            handleValidatedTranslation(translationRecord, qualityScore: qualityScore, warnings: warnings, completion: completion)

        case .valid(let qualityScore):
            handleValidatedTranslation(translationRecord, qualityScore: qualityScore, warnings: [], completion: completion)
        }
    }

    private func handleValidatedTranslation(
        _ translationRecord: TranslationRecord,
        qualityScore: Double,
        warnings: [ValidationWarning],
        completion: @escaping (Result<Void, ContributionError>) -> Void
    ) {
        let isNetworkAvailable = contributionSyncManager.isNetworkAvailable()

        do {
            let contribution = Contribution(context: coreDataContext)
            contribution.humanText = translationRecord.humanText
            contribution.dogTranslation = translationRecord.dogTranslation
            contribution.qualityScore = qualityScore
            contribution.displayStatus = .validated
            contribution.timestamp = Date()
            contribution.validationNotes = warnings.map { $0.errorDescription ?? "Unknown warning" }.joined(separator: "; ")

            try coreDataContext.save()

            if isNetworkAvailable {
                contributionSyncManager.submitContribution(contribution) { result in
                    switch result {
                    case .success():
                        contribution.displayStatus = .submitted
                        try? coreDataContext.save()
                        completion(.success(()))
                    case .failure:
                        contribution.displayStatus = .pending
                        try? coreDataContext.save()
                        completion(.failure(.networkUnavailable))
                    }
                }
            } else {
                contribution.displayStatus = .pending
                try coreDataContext.save()
                contributionSyncManager.queueContributionForSync(contribution)
                completion(.failure(.networkUnavailable))
            }
        } catch {
            completion(.failure(.coreDataSaveFailed))
        }
    }
}
