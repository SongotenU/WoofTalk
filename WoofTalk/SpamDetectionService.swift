//
//  SpamDetectionService.swift
//  WoofTalk
//
//  Spam detection service with content analysis
//

import Foundation
import NaturalLanguage

// MARK: - Spam Analysis Result

/// Result of spam analysis
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

// MARK: - Spam Confidence Level

enum SpamConfidenceLevel: String {
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
        default: return .veryHigh
        }
    }
}

// MARK: - Spam Detection Service

final class SpamDetectionService {
    
    // MARK: - Singleton
    
    static let shared = SpamDetectionService()
    
    // MARK: - Configuration
    
    struct Configuration {
        var repetitionThreshold: Double = 0.4
        var capsThreshold: Double = 0.6
        var maxLinks: Int = 3
        var minUniqueWordRatio: Double = 0.3
        var autoFlagThreshold: Double = 0.7
        var highConfidenceThreshold: Double = 0.85
    }
    
    var configuration = Configuration()
    
    // MARK: - Private Properties
    
    private let spamAnalyzer = SpamAnalyzer()
    private var submissionHistory: [String: [Date]] = [:]
    private let maxSubmissionsPerHour = 10
    
    // Blacklisted patterns (simplified for demo - in production use more comprehensive lists)
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
        "http://tinyurl"
    ]
    
    private let suspiciousPhrases: [String] = [
        "buy now",
        "click below",
        "discount",
        "offer",
        "prize",
        "winner",
        "urgent",
        "immediately",
        "act fast"
    ]
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// Analyzes content for spam indicators
    /// - Parameters:
    ///   - content: The text content to analyze
    ///   - userId: Optional user ID for behavior analysis
    /// - Returns: SpamAnalysisResult with confidence and details
    func analyze(content: String, userId: String? = nil) -> SpamAnalysisResult {
        let combinedContent = content
        
        // Perform various spam checks
        let repetitionScore = spamAnalyzer.calculateRepetitionScore(text: combinedContent)
        let capsRatio = spamAnalyzer.calculateCapsRatio(text: combinedContent)
        let patternScore = spamAnalyzer.calculatePatternScore(text: combinedContent)
        let linkCount = spamAnalyzer.countLinks(text: combinedContent)
        let wordCount = spamAnalyzer.wordCount(text: combinedContent)
        let uniqueWordRatio = spamAnalyzer.calculateUniqueWordRatio(text: combinedContent)
        
        // Collect reasons
        var reasons: [SpamAnalysisResult.SpamReason] = []
        
        if repetitionScore > configuration.repetitionThreshold {
            reasons.append(.repetitiveContent)
        }
        
        if capsRatio > configuration.capsThreshold {
            reasons.append(.excessiveCaps)
        }
        
        if patternScore > 0.5 {
            reasons.append(.suspiciousPatterns)
        }
        
        if isBlacklisted(text: combinedContent) {
            reasons.append(.blacklistedContent)
        }
        
        if linkCount > configuration.maxLinks {
            reasons.append(.tooManyLinks)
        }
        
        if uniqueWordRatio < configuration.minUniqueWordRatio {
            reasons.append(.repetitiveContent)
        }
        
        // Check for duplicate submissions
        if let userId = userId, isDuplicateSubmission(userId: userId, content: content) {
            reasons.append(.duplicateSubmission)
        }
        
        // Check for suspicious user behavior
        if let userId = userId, hasSuspiciousBehavior(userId: userId) {
            reasons.append(.suspiciousUserBehavior)
        }
        
        // Calculate overall confidence
        let confidence = calculateOverallConfidence(
            repetitionScore: repetitionScore,
            capsRatio: capsRatio,
            patternScore: patternScore,
            hasBlacklistedContent: reasons.contains(.blacklistedContent),
            hasTooManyLinks: reasons.contains(.tooManyLinks),
            isDuplicate: reasons.contains(.duplicateSubmission),
            suspiciousBehavior: reasons.contains(.suspiciousUserBehavior)
        )
        
        let isSpam = confidence > configuration.autoFlagThreshold
        
        return SpamAnalysisResult(
            isSpam: isSpam,
            confidence: confidence,
            reasons: reasons,
            details: SpamAnalysisResult.SpamAnalysisDetails(
                repetitionScore: repetitionScore,
                capsRatio: capsRatio,
                patternScore: patternScore,
                linkCount: linkCount,
                wordCount: wordCount,
                uniqueWordRatio: uniqueWordRatio
            )
        )
    }
    
    /// Quick check for spam (simplified for performance-critical paths)
    /// - Parameter content: Text to check
    /// - Returns: True if likely spam
    func isLikelySpam(_ content: String) -> Bool {
        let result = analyze(content: content)
        return result.isSpam
    }
    
    /// Records a submission for duplicate detection
    /// - Parameters:
    ///   - userId: User who submitted
    ///   - content: Content submitted
    func recordSubmission(userId: String, content: String) {
        let key = "\(userId):\(content.lowercased().hashValue)"
        let now = Date()
        
        if submissionHistory[key] == nil {
            submissionHistory[key] = []
        }
        submissionHistory[key]?.append(now)
        
        // Clean up old entries (older than 1 hour)
        let oneHourAgo = now.addingTimeInterval(-3600)
        submissionHistory[key] = submissionHistory[key]?.filter { $0 > oneHourAgo }
    }
    
    // MARK: - Private Methods
    
    private func isBlacklisted(text: String) -> Bool {
        let lowercased = text.lowercased()
        return blacklistedPatterns.contains { lowercased.contains($0) }
    }
    
    private func isDuplicateSubmission(userId: String, content: String) -> Bool {
        let key = "\(userId):\(content.lowercased().hashValue)"
        guard let history = submissionHistory[key], !history.isEmpty else {
            return false
        }
        
        // Consider duplicate if submitted within last hour
        let oneHourAgo = Date().addingTimeInterval(-3600)
        return history.contains { $0 > oneHourAgo }
    }
    
    private func hasSuspiciousBehavior(userId: String) -> Bool {
        // Check total submissions in last hour
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
        var confidence: Double = 0.0
        
        // Weight factors
        let repetitionWeight = 0.25
        let capsWeight = 0.15
        let patternWeight = 0.20
        let blacklistWeight = 0.25
        let linkWeight = 0.10
        let duplicateWeight = 0.15
        let behaviorWeight = 0.20
        
        // Calculate weighted contribution
        confidence += repetitionScore * repetitionWeight
        confidence += capsRatio * capsWeight
        confidence += patternScore * patternWeight
        confidence += (hasBlacklistedContent ? 1.0 : 0.0) * blacklistWeight
        confidence += (hasTooManyLinks ? 0.8 : 0.0) * linkWeight
        confidence += (isDuplicate ? 0.9 : 0.0) * duplicateWeight
        confidence += (suspiciousBehavior ? 0.9 : 0.0) * behaviorWeight
        
        // Cap at 1.0
        return min(confidence, 1.0)
    }
}

// MARK: - SpamAnalyzer

/// Internal analyzer for specific spam detection metrics
final class SpamAnalyzer {
    
    /// Calculates repetition score (0.0 = no repetition, 1.0 = highly repetitive)
    func calculateRepetitionScore(text: String) -> Double {
        let words = text.lowercased().split(separator: " ").map(String.init)
        guard words.count > 1 else { return 0.0 }
        
        // Count consecutive repeated words or n-grams
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
        
        // Calculate repetition ratio
        let maxPossibleRepeats = words.count - 1
        guard maxPossibleRepeats > 0 else { return 0.0 }
        
        return min(Double(repeatCount) / Double(maxPossibleRepeats), 1.0)
    }
    
    /// Calculates ratio of uppercase characters to total (0.0 = no caps, 1.0 = all caps)
    func calculateCapsRatio(text: String) -> Double {
        let letters = text.filter { $0.isLetter }
        guard !letters.isEmpty else { return 0.0 }
        
        let uppercaseCount = letters.filter { $0.isUppercase }.count
        return Double(uppercaseCount) / Double(letters.count)
    }
    
    /// Calculates suspicious pattern score (0.0 = no patterns, 1.0 = suspicious patterns found)
    func calculatePatternScore(text: String) -> Double {
        let lowercased = text.lowercased()
        let suspiciousPhrases = [
            "click here", "free money", "act now", "limited time",
            "buy now", "special offer", "congratulations", "winner",
            "claim your prize", "verify", "urgent", "immediately"
        ]
        
        var matches = 0
        for phrase in suspiciousPhrases {
            if lowercased.contains(phrase) {
                matches += 1
            }
        }
        
        // Normalize to 0-1
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
    
    /// Counts total words in text
    func wordCount(text: String) -> Int {
        return text.split(separator: " ").count
    }
    
    /// Calculates ratio of unique words to total words
    func calculateUniqueWordRatio(text: String) -> Double {
        let words = text.lowercased().split(separator: " ").map(String.init)
        guard !words.isEmpty else { return 1.0 }
        
        let uniqueWords = Set(words)
        return Double(uniqueWords.count) / Double(words.count)
    }
}
