// MARK: - TranslationQualityScorer

import Foundation

final class TranslationQualityScorer {
    
    static let shared = TranslationQualityScorer()
    
    private init() {}
    
    func score(input: String, output: String, direction: TranslationDirection) -> TranslationQualityScore {
        var confidence: Double = 0.5
        var accuracy: Double = 0.5
        
        if !input.isEmpty && !output.isEmpty {
            confidence = calculateConfidence(input: input, output: output, direction: direction)
            accuracy = confidence * 0.95
        }
        
        return TranslationQualityScore(confidence: confidence, estimatedAccuracy: accuracy)
    }
    
    private func calculateConfidence(input: String, output: String, direction: TranslationDirection) -> Double {
        var score: Double = 0.6
        
        let inputLower = input.lowercased()
        let outputLower = output.lowercased()
        
        if inputLower == outputLower {
            score -= 0.2
        }
        
        let knownPhrases = getKnownPhrases()
        if let _ = knownPhrases[direction]?[inputLower] {
            score += 0.25
        }
        
        if output.count > input.count * 3 {
            score -= 0.1
        }
        
        return min(max(score, 0.0), 1.0)
    }
    
    private func getKnownPhrases() -> [TranslationDirection: [String: (text: String, confidence: Double)]] {
        return [
            .dogToHuman: [
                "woof woof": ("Hello! I'm happy to see you!", 0.92),
                "woof woof woof": ("Let's go for a walk!", 0.88),
                "bark bark": ("Alert! Something is happening", 0.82),
                "howl": ("I'm calling for my pack", 0.80)
            ],
            .humanToDog: [
                "hello": ("Woof! Hello!", 0.90),
                "good boy": ("Tail wag! I'm a good boy!", 0.88),
                "walk": ("Walk! Walk! Let's go!", 0.92),
                "food": ("Yum! Food time!", 0.90)
            ]
        ]
    }
    
    func compareTranslations(ai: String, ruleBased: String, reference: String?) -> (aiBetter: Bool, difference: Double) {
        let aiScore = score(input: reference ?? "", output: ai, direction: .dogToHuman).confidence
        let rbScore = score(input: reference ?? "", output: ruleBased, direction: .dogToHuman).confidence
        
        let difference = aiScore - rbScore
        return (difference > 0, abs(difference))
    }
}