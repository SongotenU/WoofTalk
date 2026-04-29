import Foundation
import NaturalLanguage

struct SpamAnalysisResult {
    let isSpam: Bool
    let confidence: Double
    let reasons: [SpamReason]
    let details: SpamAnalysisDetails
    
    enum SpamReason: String, Codable {
        case repetitiveContent = "repetitive_content"
        case excessiveCaps = "excessive_caps"
        case suspiciousPatterns = "suspicious_patterns"
        case blacklistedContent = "blacklisted_content"
        case tooManyLinks = "too_many_links"
        case duplicateSubmission = "duplicate_submission"
        case suspiciousUserBehavior = "suspicious_user_behavior"
    }
    
    struct SpamAnalysisDetails {
        let repetitionScore: Double
        let capsRatio: Double
        let patternScore: Double
        let linkCount: Int
        let wordCount: Int
        let uniqueWordRatio: Double
    }
}

enum SpamConfidenceLevel: String, CaseIterable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
    
    var threshold: Double {
        switch self {
        case .none: return 0.0
        case .low: return 0.2
        case .medium: return 0.4
        case .high: return 0.7
        case .veryHigh: return 0.85
        }
    }
    
    static func from(confidence: Double) -> SpamConfidenceLevel {
        switch confidence {
        case 0..<0.2: return .none
        case 0.2..<0.4: return .low
        case 0.4..<0.7: return .medium
        case 0.7..<0.85: return .high
        case 0.85...1.0: return .veryHigh
        default: return .none
        }
    }
}

final class SpamDetectionService {
    
    static let shared = SpamDetectionService()
    
    struct Configuration {
        var repetitionThreshold: Double = 0.4
        var capsThreshold: Double = 0.6
        var maxLinks: Int = 3
        var minUniqueWordRatio: Double = 0.3
        var autoFlagThreshold: Double = 0.7
        var highConfidenceThreshold: Double = 0.85
    }
    
    var configuration = Configuration()
    
    private let spamAnalyzer = SpamAnalyzer()
    private var submissionHistory: [String: [Date]] = [:]
    private let maxSubmissionsPerHour = 10
    
    private let blacklistedPatterns: [String] = [
        "click here",
        "free money",
        "act now",
        "limited time",
        "buy now",
        "special offer",
        "congratulations winner",
        "claim your prize",
        "verify your account",
        "suspicious link",
        "http://bit.ly",
        "http://tinyurl",
        "click below",
        "discount",
        "prize",
        "winner",
        "urgent",
        "immediately",
        "act fast"
    ]

    private init() {}

    func analyze(content: String, userId: String? = nil) -> SpamAnalysisResult {
        let repetitionScore = spamAnalyzer.calculateRepetitionScore(text: content)
        let capsRatio = spamAnalyzer.calculateCapsRatio(text: content)
        let patternScore = spamAnalyzer.calculatePatternScore(text: content)
        let linkCount = spamAnalyzer.countLinks(text: content)
        let wordCount = spamAnalyzer.wordCount(text: content)
        let uniqueWordRatio = spamAnalyzer.calculateUniqueWordRatio(text: content)

        var reasons: [SpamAnalysisResult.SpamReason] = []

        if repetitionScore > configuration.repetitionThreshold { reasons.append(.repetitiveContent) }
        if capsRatio > configuration.capsThreshold { reasons.append(.excessiveCaps) }
        if patternScore > 0.5 { reasons.append(.suspiciousPatterns) }
        if isBlacklisted(text: content) { reasons.append(.blacklistedContent) }
        if linkCount > configuration.maxLinks { reasons.append(.tooManyLinks) }
        if uniqueWordRatio < configuration.minUniqueWordRatio { reasons.append(.repetitiveContent) }
        if let userId = userId, isDuplicateSubmission(userId: userId, content: content) { reasons.append(.duplicateSubmission) }
        if let userId = userId, hasSuspiciousBehavior(userId: userId) { reasons.append(.suspiciousUserBehavior) }

        let confidence = calculateOverallConfidence(
            repetitionScore: repetitionScore, capsRatio: capsRatio, patternScore: patternScore,
            hasBlacklistedContent: reasons.contains(.blacklistedContent),
            hasTooManyLinks: reasons.contains(.tooManyLinks),
            isDuplicate: reasons.contains(.duplicateSubmission),
            suspiciousBehavior: reasons.contains(.suspiciousUserBehavior)
        )

        return SpamAnalysisResult(
            isSpam: confidence > configuration.autoFlagThreshold, confidence: confidence, reasons: reasons,
            details: SpamAnalysisResult.SpamAnalysisDetails(
                repetitionScore: repetitionScore, capsRatio: capsRatio, patternScore: patternScore,
                linkCount: linkCount, wordCount: wordCount, uniqueWordRatio: uniqueWordRatio
            )
        )
    }
    
    func isLikelySpam(_ content: String) -> Bool {
        analyze(content: content).isSpam
    }

    func recordSubmission(userId: String, content: String) {
        let key = "\(userId):\(content.lowercased().hashValue)"
        let now = Date()
        if submissionHistory[key] == nil { submissionHistory[key] = [] }
        submissionHistory[key]?.append(now)
        submissionHistory[key] = submissionHistory[key]?.filter { $0 > now.addingTimeInterval(-3600) }
    }

    private func isBlacklisted(text: String) -> Bool {
        let lowercased = text.lowercased()
        return blacklistedPatterns.contains { lowercased.contains($0) }
    }
    
    private func isDuplicateSubmission(userId: String, content: String) -> Bool {
        let key = "\(userId):\(content.lowercased().hashValue)"
        guard let history = submissionHistory[key], !history.isEmpty else { return false }
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return history.contains { $0 > oneHourAgo }
    }

    private func hasSuspiciousBehavior(userId: String) -> Bool {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentSubmissions = submissionHistory
            .filter { $0.key.hasPrefix(userId) }
            .flatMap { $0.value }
            .filter { $0 > oneHourAgo }
            .count
        return recentSubmissions > maxSubmissionsPerHour
    }

    private func calculateOverallConfidence(
        repetitionScore: Double,
        capsRatio: Double,
        patternScore: Double,
        hasBlacklistedContent: Bool,
        hasTooManyLinks: Bool,
        isDuplicate: Bool,
        suspiciousBehavior: Bool
    ) -> Double {
        var confidence = 0.0

        // Weighted scores (sum = 1.0)
        confidence += repetitionScore * 0.2
        confidence += capsRatio * 0.15
        confidence += patternScore * 0.15
        confidence += (hasBlacklistedContent ? 1.0 : 0.0) * 0.25
        confidence += (hasTooManyLinks ? 0.8 : 0.0) * 0.1
        confidence += (isDuplicate ? 0.9 : 0.0) * 0.1
        confidence += (suspiciousBehavior ? 0.9 : 0.0) * 0.1

        return min(confidence, 1.0)
    }
}

// MARK: - SpamAnalyzer

final class SpamAnalyzer {
    
    func calculateRepetitionScore(text: String) -> Double {
        let words = text.lowercased().split(separator: " ").map(String.init)
        guard words.count > 1 else { return 0.0 }
        
        var repeatCount = 0
        var consecutiveRepeats = 0
        
        for i in 1..<words.count {
            if words[i] == words[i-1] {
                consecutiveRepeats += 1
                repeatCount += consecutiveRepeats
            } else {
                consecutiveRepeats = 0
            }
        }
        
        let maxPossibleRepeats = words.count - 1
        guard maxPossibleRepeats > 0 else { return 0.0 }
        
        return min(Double(repeatCount) / Double(maxPossibleRepeats), 1.0)
    }
    
    func calculateCapsRatio(text: String) -> Double {
        let letters = text.filter { $0.isLetter }
        guard !letters.isEmpty else { return 0.0 }
        
        let uppercaseCount = letters.filter { $0.isUppercase }.count
        return Double(uppercaseCount) / Double(letters.count)
    }
    
    func calculatePatternScore(text: String) -> Double {
        let lowercased = text.lowercased()
        let matches = blacklistedPatterns.filter { lowercased.contains($0) }.count
        return min(Double(matches) / 3.0, 1.0)
    }
    
    /// Counts number of links in text
    func countLinks(text: String) -> Int {
        let linkPattern = "https?://[\\w\\d\\-._~:/?#\\[\\]@!$&'()*+,;=%]+"
        guard let regex = try? NSRegularExpression(pattern: linkPattern, options: .caseInsensitive) else {
            return 0
        }
        
        let range = NSRange(text.startIndex..., in: text)
        return regex.numberOfMatches(in: text, options: [], range: range)
    }
    
    func wordCount(text: String) -> Int {
        return text.split(separator: " ").count
    }
    
    func calculateUniqueWordRatio(text: String) -> Double {
        let words = text.lowercased().split(separator: " ").map(String.init)
        guard !words.isEmpty else { return 1.0 }
        
        let uniqueWords = Set(words)
        return Double(uniqueWords.count) / Double(words.count)
    }
}
