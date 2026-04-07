import Foundation
import CoreData

final class AutoModerationService {
    
    static let shared = AutoModerationService(coreDataContext: PersistenceController.shared.container.viewContext)
    
    private let coreDataContext: NSManagedObjectContext
    private let policy = QualityThresholdPolicy.shared
    private let spamDetectionService = SpamDetectionService.shared
    private let communityPhraseManager = CommunityPhraseManager.shared
    
    private var autoModerationEnabled = true
    
    init(coreDataContext: NSManagedObjectContext) {
        self.coreDataContext = coreDataContext
    }
    
    func setEnabled(_ enabled: Bool) {
        autoModerationEnabled = enabled
    }
    
    func processContribution(_ contribution: Contribution) -> AutoModerationResult {
        guard autoModerationEnabled else {
            return AutoModerationResult(
                success: true,
                action: .manualReview,
                message: "Auto-moderation disabled"
            )
        }
        
        let evaluation = policy.evaluateWithSpamCheck(contribution: contribution)
        
        switch evaluation.action {
        case .autoApprove:
            return approveContribution(contribution, reason: evaluation.reason)
            
        case .autoReject:
            return rejectContribution(contribution, reason: evaluation.reason)
            
        case .manualReview, .escalate:
            return AutoModerationResult(
                success: true,
                action: evaluation.action,
                message: evaluation.reason
            )
        }
    }
    
    func processPendingContributions() -> BatchModerationResult {
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", ContributionStatus.pending.rawValue)
        
        do {
            let pendingContributions = try coreDataContext.fetch(fetchRequest)
            var approved = 0
            var rejected = 0
            var pending = 0
            var errors: [String] = []
            
            for contribution in pendingContributions {
                let result = processContribution(contribution)
                
                switch result.action {
                case .autoApprove:
                    approved += 1
                case .autoReject:
                    rejected += 1
                case .manualReview, .escalate:
                    pending += 1
                }
                
                if !result.success, let error = result.message {
                    errors.append(error)
                }
            }
            
            return BatchModerationResult(
                totalProcessed: pendingContributions.count,
                approved: approved,
                rejected: rejected,
                requiringReview: pending,
                errors: errors
            )
            
        } catch {
            return BatchModerationResult(
                totalProcessed: 0,
                approved: 0,
                rejected: 0,
                requiringReview: 0,
                errors: [error.localizedDescription]
            )
        }
    }
    
    func overrideDecision(contribution: Contribution, newAction: ModerationAction, moderatorId: String, reason: String) throws {
        switch newAction {
        case .autoApprove:
            _ = approveContribution(contribution, reason: "Manual override: \(reason)")
        case .autoReject:
            _ = rejectContribution(contribution, reason: "Manual override: \(reason)")
        case .manualReview, .escalate:
            contribution.validationNotes = "Manual override to review: \(reason)"
            try coreDataContext.save()
        }
    }
    
    private func approveContribution(_ contribution: Contribution, reason: String) -> AutoModerationResult {
        do {
            try communityPhraseManager.createCommunityPhrase(from: contribution)
            return AutoModerationResult(
                success: true,
                action: .autoApprove,
                message: "Auto-approved: \(reason)"
            )
        } catch {
            return AutoModerationResult(
                success: false,
                action: .autoApprove,
                message: "Failed to approve: \(error.localizedDescription)"
            )
        }
    }
    
    private func rejectContribution(_ contribution: Contribution, reason: String) -> AutoModerationResult {
        contribution.displayStatus = .rejected
        contribution.validationNotes = "Auto-rejected: \(reason)"
        
        do {
            try coreDataContext.save()
            return AutoModerationResult(
                success: true,
                action: .autoReject,
                message: "Auto-rejected: \(reason)"
            )
        } catch {
            return AutoModerationResult(
                success: false,
                action: .autoReject,
                message: "Failed to reject: \(error.localizedDescription)"
            )
        }
    }
    
    func getAutoModerationStats() -> AutoModerationStats {
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        
        do {
            let allContributions = try coreDataContext.fetch(fetchRequest)
            let pending = allContributions.filter { $0.displayStatus == .pending }.count
            let approved = allContributions.filter { $0.displayStatus == .approved }.count
            let rejected = allContributions.filter { $0.displayStatus == .rejected }.count
            
            let autoApproved = allContributions.filter {
                $0.displayStatus == .approved && ($0.validationNotes?.contains("Auto-approved") ?? false)
            }.count
            
            let autoRejected = allContributions.filter {
                $0.displayStatus == .rejected && ($0.validationNotes?.contains("Auto-rejected") ?? false)
            }.count
            
            return AutoModerationStats(
                totalContributions: allContributions.count,
                pendingCount: pending,
                approvedCount: approved,
                rejectedCount: rejected,
                autoApprovedCount: autoApproved,
                autoRejectedCount: autoRejected,
                autoApprovalRate: approved > 0 ? Double(autoApproved) / Double(approved) : 0,
                autoRejectionRate: rejected > 0 ? Double(autoRejected) / Double(rejected) : 0
            )
        } catch {
            return AutoModerationStats(
                totalContributions: 0,
                pendingCount: 0,
                approvedCount: 0,
                rejectedCount: 0,
                autoApprovedCount: 0,
                autoRejectedCount: 0,
                autoApprovalRate: 0,
                autoRejectionRate: 0
            )
        }
    }
}

struct AutoModerationResult {
    let success: Bool
    let action: ModerationAction
    let message: String
}

struct BatchModerationResult {
    let totalProcessed: Int
    let approved: Int
    let rejected: Int
    let requiringReview: Int
    let errors: [String]
    
    var summary: String {
        return "Processed \(totalProcessed): \(approved) approved, \(rejected) rejected, \(requiringReview) require review"
    }
}

struct AutoModerationStats {
    let totalContributions: Int
    let pendingCount: Int
    let approvedCount: Int
    let rejectedCount: Int
    let autoApprovedCount: Int
    let autoRejectedCount: Int
    let autoApprovalRate: Double
    let autoRejectionRate: Double
}
