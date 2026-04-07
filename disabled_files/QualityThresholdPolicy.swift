import Foundation
import CoreData

enum ModerationAction: String, Codable {
    case autoApprove = "auto_approve"
    case autoReject = "auto_reject"
    case manualReview = "manual_review"
    case escalate = "escalate"
}

struct QualityThreshold {
    let minQualityScore: Double
    let maxQualityScore: Double
    let action: ModerationAction
    let reason: String
    
    func evaluate(qualityScore: Double) -> Bool {
        return qualityScore >= minQualityScore && qualityScore <= maxQualityScore
    }
}

final class QualityThresholdPolicy {
    
    static let shared = QualityThresholdPolicy()
    
    private var thresholds: [QualityThreshold] = []
    private let spamDetectionService = SpamDetectionService.shared
    
    private init() {
        setupDefaultThresholds()
    }
    
    private func setupDefaultThresholds() {
        thresholds = [
            QualityThreshold(
                minQualityScore: 0.85,
                maxQualityScore: 1.0,
                action: .autoApprove,
                reason: "High quality content"
            ),
            QualityThreshold(
                minQualityScore: 0.0,
                maxQualityScore: 0.3,
                action: .autoReject,
                reason: "Low quality content"
            ),
            QualityThreshold(
                minQualityScore: 0.5,
                maxQualityScore: 0.84,
                action: .manualReview,
                reason: "Requires moderator review"
            ),
            QualityThreshold(
                minQualityScore: 0.3,
                maxQualityScore: 0.49,
                action: .manualReview,
                reason: "Borderline quality - needs review"
            )
        ]
    }
    
    func addThreshold(_ threshold: QualityThreshold) {
        thresholds.append(threshold)
        thresholds.sort { $0.minQualityScore > $1.minQualityScore }
    }
    
    func removeThreshold(at index: Int) {
        guard index < thresholds.count else { return }
        thresholds.remove(at: index)
    }
    
    func evaluate(contribution: Contribution) -> PolicyEvaluationResult {
        let qualityScore = contribution.qualityScore
        
        for threshold in thresholds {
            if threshold.evaluate(qualityScore: qualityScore) {
                return PolicyEvaluationResult(
                    action: threshold.action,
                    reason: threshold.reason,
                    qualityScore: qualityScore,
                    confidence: abs(qualityScore - (threshold.minQualityScore + threshold.maxQualityScore) / 2) / ((threshold.maxQualityScore - threshold.minQualityScore) / 2)
                )
            }
        }
        
        return PolicyEvaluationResult(
            action: .manualReview,
            reason: "No matching threshold",
            qualityScore: qualityScore,
            confidence: 0.0
        )
    }
    
    func evaluateWithSpamCheck(contribution: Contribution) -> PolicyEvaluationResult {
        guard let humanText = contribution.humanText else {
            return PolicyEvaluationResult(
                action: .manualReview,
                reason: "No content to evaluate",
                qualityScore: contribution.qualityScore,
                confidence: 0.0
            )
        }
        
        let spamResult = spamDetectionService.analyze(content: humanText)
        
        if spamResult.confidence > 0.85 {
            return PolicyEvaluationResult(
                action: .autoReject,
                reason: "High confidence spam detected",
                qualityScore: contribution.qualityScore,
                confidence: spamResult.confidence
            )
        }
        
        if spamResult.confidence > 0.7 {
            return PolicyEvaluationResult(
                action: .escalate,
                reason: "Potential spam - escalated for review",
                qualityScore: contribution.qualityScore,
                confidence: spamResult.confidence
            )
        }
        
        return evaluate(contribution: contribution)
    }
    
    func getThresholds() -> [QualityThreshold] {
        return thresholds
    }
    
    func resetToDefaults() {
        setupDefaultThresholds()
    }
}

struct PolicyEvaluationResult {
    let action: ModerationAction
    let reason: String
    let qualityScore: Double
    let confidence: Double
    
    var requiresManualReview: Bool {
        return action == .manualReview || action == .escalate
    }
}
