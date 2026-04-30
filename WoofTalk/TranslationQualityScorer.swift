// MARK: - TranslationQualityScorer

import Foundation

final class TranslationQualityScorer {
    func score(input: String, output: String, direction: TranslationDirection) -> TranslationQualityScore {
        guard !input.isEmpty, !output.isEmpty else {
            return TranslationQualityScore(confidence: 0.5)
        }

        var score = 0.6
        let inputLower = input.lowercased()

        if inputLower == output.lowercased() {
            score -= 0.2
        }

        if AITranslationService.enhancedTranslations[direction]?[inputLower] != nil {
            score += 0.25
        }

        if output.count > input.count * 3 {
            score -= 0.1
        }

        return TranslationQualityScore(confidence: min(max(score, 0.0), 1.0))
    }

    func compareTranslations(ai: String, ruleBased: String, reference: String?) -> (aiBetter: Bool, difference: Double) {
        let aiScore = score(input: reference ?? "", output: ai, direction: .dogToHuman).confidence
        let rbScore = score(input: reference ?? "", output: ruleBased, direction: .dogToHuman).confidence

        let difference = aiScore - rbScore
        return (difference > 0, abs(difference))
    }
}