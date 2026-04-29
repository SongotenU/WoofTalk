import Foundation

enum ModerationAction: String, Codable {
    case autoApprove = "auto_approve"
    case autoReject = "auto_reject"
    case manualReview = "manual_review"
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

    private init() {
        thresholds = [
            QualityThreshold(minQualityScore: 0.85, maxQualityScore: 1.0, action: .autoApprove, reason: "High quality"),
            QualityThreshold(minQualityScore: 0.0, maxQualityScore: 0.3, action: .autoReject, reason: "Low quality"),
            QualityThreshold(minQualityScore: 0.5, maxQualityScore: 0.84, action: .manualReview, reason: "Needs review")
        ]
    }

    func evaluate(qualityScore: Double) -> ModerationAction {
        for threshold in thresholds where threshold.evaluate(qualityScore: qualityScore) {
            return threshold.action
        }
        return .manualReview
    }
}

struct PolicyEvaluationResult {
    let action: ModerationAction
    let reason: String
    let qualityScore: Double
}
