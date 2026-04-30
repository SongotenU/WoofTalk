import Foundation
import NaturalLanguage

struct TranslationRecord {
    let humanText: String
    let dogTranslation: String
}

enum ValidationResult {
    case valid(qualityScore: Double)
    case invalid(errors: [ValidationError])
    case warning(qualityScore: Double, warnings: [ValidationWarning])
}

enum ValidationError: LocalizedError {
    case emptyField(field: String)
    case tooShort(field: String, minLength: Int, actualLength: Int)
    case tooLong(field: String, maxLength: Int, actualLength: Int)
    case profanityDetected
    case notEnglish
    case duplicateTranslation
    case lowConfidence

    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "The \(field) field cannot be empty."
        case .tooShort(let field, let minLength, let actualLength):
            return "The \(field) field must be at least \(minLength) characters (\(actualLength) provided)."
        case .tooLong(let field, let maxLength, let actualLength):
            return "The \(field) field must be at most \(maxLength) characters (\(actualLength) provided)."
        case .profanityDetected:
            return "The text contains inappropriate language."
        case .notEnglish:
            return "The text must be in English."
        case .duplicateTranslation:
            return "This translation already exists."
        case .lowConfidence:
            return "Translation confidence is too low."
        }
    }
}

enum ValidationWarning: LocalizedError {
    case lowQuality(qualityScore: Double)
    case potentialDuplicate

    var errorDescription: String? {
        switch self {
        case .lowQuality(let qualityScore):
            return "Translation quality is low (score: \(qualityScore)). Consider improving it."
        case .potentialDuplicate:
            return "This translation may be similar to existing ones."
        }
    }
}

final class ContributionValidationService {

    private var existingTranslations: Set<String> = []

    func validate(translationRecord: TranslationRecord) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        let humanText = translationRecord.humanText
        let dogTranslation = translationRecord.dogTranslation

        if humanText.isEmpty { errors.append(.emptyField(field: "humanText")) }
        if dogTranslation.isEmpty { errors.append(.emptyField(field: "dogTranslation")) }

        if humanText.count == 1 { errors.append(.tooShort(field: "humanText", minLength: 2, actualLength: 1)) }
        if humanText.count > 100 { errors.append(.tooLong(field: "humanText", maxLength: 100, actualLength: humanText.count)) }
        if dogTranslation.count == 1 { errors.append(.tooShort(field: "dogTranslation", minLength: 2, actualLength: 1)) }
        if dogTranslation.count > 50 { errors.append(.tooLong(field: "dogTranslation", maxLength: 50, actualLength: dogTranslation.count)) }

        if !isEnglish(text: humanText) || !isEnglish(text: dogTranslation) {
            errors.append(.notEnglish)
        }

        if existingTranslations.contains(humanText.lowercased()) {
            errors.append(.duplicateTranslation)
        }

        let confidenceScore = getMLConfidenceScore(humanText: humanText, dogText: dogTranslation)

        if confidenceScore < 0.5 {
            errors.append(.lowConfidence)
        } else if confidenceScore < 0.7 {
            warnings.append(.lowQuality(qualityScore: confidenceScore))
        }

        existingTranslations.insert(humanText.lowercased())

        if !errors.isEmpty { return .invalid(errors: errors) }
        if !warnings.isEmpty { return .warning(qualityScore: confidenceScore, warnings: warnings) }
        return .valid(qualityScore: confidenceScore)
    }

    private func isEnglish(text: String) -> Bool {
        let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
        tagger.string = text
        return tagger.dominantLanguage?.hasPrefix("en") ?? false
    }

    private func getMLConfidenceScore(humanText: String, dogText: String) -> Double {
        TranslationModels.shared.getConfidence(humanText, direction: .humanToDog) ?? calculateFallbackConfidence(humanText: humanText, dogText: dogText)
    }

    private func calculateFallbackConfidence(humanText: String, dogText: String) -> Double {
        let minLength = min(humanText.count, dogText.count)
        let maxLength = max(humanText.count, dogText.count)
        guard maxLength > 0 else { return 0.5 }

        var matches = 0
        for i in 0..<minLength {
            if humanText[humanText.index(humanText.startIndex, offsetBy: i)] == dogText[dogText.index(dogText.startIndex, offsetBy: i)] { matches += 1 }
        }
        let similarity = Double(matches) / Double(maxLength)

        let lengthPenalty = abs(humanText.count - dogText.count) < 3 ? 0.0 : 0.1
        let languagePenalty = isEnglish(text: humanText) && isEnglish(text: dogText) ? 0.0 : 0.2

        return max(0.0, min(1.0, similarity * 0.5 + 0.3 + languagePenalty - lengthPenalty))
    }
}
