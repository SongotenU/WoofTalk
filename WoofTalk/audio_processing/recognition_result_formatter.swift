//
//  recognition_result_formatter.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

import Foundation

struct RecognitionResultFormatter {
    static func formatResult(_ result: SFSpeechRecognitionResult) -> FormattedResult {
        return FormattedResult(
            text: result.bestTranscription.formattedString,
            confidence: calculateConfidence(result),
            segments: formatSegments(result.bestTranscription.segments),
            alternativeResults: formatAlternatives(result.transcriptions)
        )
    }
    
    private static func calculateConfidence(_ result: SFSpeechRecognitionResult) -> Double {
        let textLength = result.bestTranscription.formattedString.count
        if textLength == 0 {
            return 0.0
        }
        
        // Confidence calculation based on text length and number of alternatives
        let baseConfidence = 0.8
        let lengthFactor = min(1.0, Double(textLength) / 100.0)
        let alternativesFactor = 1.0 - (0.1 * Double(result.transcriptions.count - 1))
        
        return baseConfidence * lengthFactor * alternativesFactor
    }
    
    private static func formatSegments(_ segments: [SFTranscriptionSegment]) -> [Segment] {
        return segments.map { segment in
            return Segment(
                substring: segment.substring,
                timestamp: segment.timestamp,
                duration: segment.duration,
                confidence: segment.confidence ?? 0.8,
                speakingRate: calculateSpeakingRate(segment)
            )
        }
    }
    
    private static func calculateSpeakingRate(_ segment: SFTranscriptionSegment) -> Double {
        if segment.duration > 0 {
            return Double(segment.substring.count) / segment.duration
        }
        return 0.0
    }
    
    private static func formatAlternatives(_ alternatives: [SFTranscription]) -> [Alternative] {
        return alternatives.map { alternative in
            return Alternative(
                formattedString: alternative.formattedString,
                segments: formatSegments(alternative.segments),
                confidence: calculateConfidenceForAlternative(alternative),
                wordCount: alternative.formattedString.wordCount
            )
        }
    }
    
    private static func calculateConfidenceForAlternative(_ alternative: SFTranscription) -> Double {
        let textLength = alternative.formattedString.count
        if textLength == 0 {
            return 0.0
        }
        
        // Alternative confidence is slightly lower than best result
        let baseConfidence = 0.7
        let lengthFactor = min(1.0, Double(textLength) / 100.0)
        
        return baseConfidence * lengthFactor
    }
}

extension String {
    var wordCount: Int {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.count
    }
}

struct FormattedResult {
    let text: String
    let confidence: Double
    let segments: [Segment]
    let alternativeResults: [Alternative]
}

struct Segment {
    let substring: String
    let timestamp: TimeInterval
    let duration: TimeInterval
    let confidence: Double
    let speakingRate: Double
}

struct Alternative {
    let formattedString: String
    let segments: [Segment]
    let confidence: Double
    let wordCount: Int
}

extension RecognitionResultFormatter {
    static func formatResultForTranslation(_ result: SFSpeechRecognitionResult) -> TranslationInput {
        let formatted = formatResult(result)
        
        return TranslationInput(
            originalText: formatted.text,
            confidence: formatted.confidence,
            wordCount: formatted.text.wordCount,
            speakingRate: calculateAverageSpeakingRate(formatted.segments),
            language: NSLinguisticTagger.dominantLanguage(for: formatted.text) ?? "en-US"
        )
    }
    
    private static func calculateAverageSpeakingRate(_ segments: [Segment]) -> Double {
        let validSegments = segments.filter { $0.speakingRate > 0 }
        guard !validSegments.isEmpty else { return 0.0 }
        
        let totalWords = validSegments.reduce(0) { $0 + $1.substring.wordCount }
        let totalDuration = validSegments.reduce(0) { $0 + $1.duration }
        
        return totalDuration > 0 ? Double(totalWords) / totalDuration : 0.0
    }
}

struct TranslationInput {
    let originalText: String
    let confidence: Double
    let wordCount: Int
    let speakingRate: Double
    let language: String
}

extension RecognitionResultFormatter {
    static func formatResultForDisplay(_ result: SFSpeechRecognitionResult) -> [String: Any] {
        let formatted = formatResult(result)
        
        return [
            "text": formatted.text,
            "confidence": formatted.confidence,
            "wordCount": formatted.text.wordCount,
            "speakingRate": calculateAverageSpeakingRate(formatted.segments),
            "segmentsCount": formatted.segments.count,
            "alternativesCount": formatted.alternativeResults.count,
            "isFinal": result.isFinal
        ]
    }
    
    static func getSummaryStatistics() -> [String: Any] {
        return [
            "supportedLanguages": SFSpeechRecognizer.supportedLocales().count,
            "defaultLocale": Locale.current.identifier,
            "recognitionFormatVersion": "1.0",
            "maxAlternatives": 5 // Speech framework supports up to 5 alternatives
        ]
    }
}