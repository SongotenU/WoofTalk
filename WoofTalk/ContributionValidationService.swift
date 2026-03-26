//
//  ContributionValidationService.swift
//  WoofTalk
//
//  Created by vandopha on 3/20/26.
//

import Foundation
import NaturalLanguage
import CoreML

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

    // Static profanity filter for demonstration
    private static let profanityWords = [
        "badword1", "badword2", "badword3", "badword4", "badword5"
    ]

    // Static duplicate detection (in-memory for demo)
    private static var existingTranslations: Set<String> = []

    // MARK: - Public API

    func validate(translationRecord: TranslationRecord) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []

        // Check for empty fields
        if translationRecord.humanText.isEmpty {
            errors.append(.emptyField(field: "humanText"))
        }
        if translationRecord.dogTranslation.isEmpty {
            errors.append(.emptyField(field: "dogTranslation"))
        }

        // Check length constraints
        let humanTextLength = translationRecord.humanText.count
        let dogTranslationLength = translationRecord.dogTranslation.count

        if humanTextLength > 0 && humanTextLength < 2 {
            errors.append(.tooShort(field: "humanText", minLength: 2, actualLength: humanTextLength))
        }
        if humanTextLength > 100 {
            errors.append(.tooLong(field: "humanText", maxLength: 100, actualLength: humanTextLength))
        }
        if dogTranslationLength > 0 && dogTranslationLength < 2 {
            errors.append(.tooShort(field: "dogTranslation", minLength: 2, actualLength: dogTranslationLength))
        }
        if dogTranslationLength > 50 {
            errors.append(.tooLong(field: "dogTranslation", maxLength: 50, actualLength: dogTranslationLength))
        }

        // Check for profanity
        if containsProfanity(text: translationRecord.humanText) || containsProfanity(text: translationRecord.dogTranslation) {
            errors.append(.profanityDetected)
        }

        // Check for English language
        if !isEnglish(text: translationRecord.humanText) || !isEnglish(text: translationRecord.dogTranslation) {
            errors.append(.notEnglish)
        }

        // Check for duplicates
        if ContributionValidationService.existingTranslations.contains(translationRecord.humanText.lowercased()) {
            errors.append(.duplicateTranslation)
        }

        // Calculate ML confidence score
        let confidenceScore = getMLConfidenceScore(humanText: translationRecord.humanText, dogText: translationRecord.dogTranslation)

        // Check confidence level
        if confidenceScore < 0.5 {
            errors.append(.lowConfidence)
        } else if confidenceScore < 0.7 {
            warnings.append(.lowQuality(qualityScore: confidenceScore))
        }

        // Add to existing translations for duplicate detection
        ContributionValidationService.existingTranslations.insert(translationRecord.humanText.lowercased())

        // Return result based on errors and warnings
        if !errors.isEmpty {
            return .invalid(errors: errors)
        } else if !warnings.isEmpty {
            return .warning(qualityScore: confidenceScore, warnings: warnings)
        } else {
            return .valid(qualityScore: confidenceScore)
        }
    }

    // MARK: - Private Helper Methods

    private func containsProfanity(text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return ContributionValidationService.profanityWords.contains { lowercasedText.contains($0) }
    }

    private func isEnglish(text: String) -> Bool {
        let tagger = NSLinguisticTagger(tagSchemes: [.language], options: 0)
        tagger.string = text
        
        guard let dominantLanguage = tagger.dominantLanguage else {
            return false
        }
        
        // Consider English and its variants as valid
        return dominantLanguage.hasPrefix("en")
    }

    private func getMLConfidenceScore(humanText: String, dogText: String) -> Double {
        do {
            // Use the real TranslationModels.getConfidence method
            let models = TranslationModels.shared
            if let confidence = try models.getConfidence(humanText, direction: .humanToDog) {
                return confidence
            }
        } catch {
            // Fall back to mock implementation if ML model fails
            print("ML confidence scoring failed, using fallback: \(error)")
        }
        
        // Fallback confidence calculation
        return calculateFallbackConfidence(humanText: humanText, dogText: dogText)
    }

    private func calculateFallbackConfidence(humanText: String, dogText: String) -> Double {
        // Simple confidence estimation based on text similarity
        let similarity = calculateSimilarity(text1: humanText, text2: dogText)
        let lengthFactor = 1.0 - (abs(humanText.count - dogText.count) / max(humanText.count, dogText.count)) * 0.1
        let profanityPenalty = containsProfanity(text: humanText) || containsProfanity(text: dogText) ? 0.3 : 0.0
        let languagePenalty = isEnglish(text: humanText) && isEnglish(text: dogText) ? 0.0 : 0.2
        
        let confidence = (similarity * 0.5 + lengthFactor * 0.3 + 0.2) - profanityPenalty - languagePenalty
        return max(0.0, min(1.0, confidence))
    }

    private func calculateSimilarity(text1: String, text2: String) -> Double {
        // Simple character-level similarity for demonstration
        let longer = text1.count > text2.count ? text1 : text2
        let shorter = text1.count > text2.count ? text2 : text1

        let longerArray = Array(longer)
        let shorterArray = Array(shorter)

        var matches = 0
        for i in 0..<shorterArray.count {
            if i < longerArray.count && shorterArray[i] == longerArray[i] {
                matches += 1
            }
        }

        return Double(matches) / Double(longerArray.count)
    }
}