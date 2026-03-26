// MARK: - CommunityPhrase Extensions

import Foundation
import SwiftUI

/// Display extensions for CommunityPhrase
extension CommunityPhrase {
    
    /// Quality tier for UI indicators
    enum QualityTier: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .excellent: return "star.fill"
            case .good: return "star.leadinghalf.filled"
            case .fair: return "star"
            case .poor: return "exclamationmark.triangle"
            }
        }
    }
    
    /// Formatted quality score for display (e.g., "85%")
    var qualityScoreFormatted: String {
        return "\(Int(qualityScore * 100))%"
    }
    
    /// Quality tier based on score
    var qualityTier: QualityTier {
        switch qualityScore {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        default: return .poor
        }
    }
    
    /// Display text for submitter
    var contributorDisplay: String {
        return submitter?.username ?? "Anonymous"
    }
    
    /// Human-readable age string
    var ageDisplayString: String {
        guard let timestamp = timestamp else { return "Unknown" }
        
        let calendar = Calendar.current
        let now = Date()
        
        if let days = calendar.dateComponents([.day], from: timestamp, to: now).day {
            if days > 30 { return ">1 month ago" }
            if days > 0 { return "\(days) day\(days == 1 ? "" : "s") ago" }
        }
        
        if let hours = calendar.dateComponents([.hour], from: timestamp, to: now).hour {
            if hours > 0 { return "\(hours) hour\(hours == 1 ? "" : "s") ago" }
        }
        
        if let minutes = calendar.dateComponents([.minute], from: timestamp, to: now).minute {
            return "\(minutes) min ago"
        }
        
        return "Just now"
    }
    
    /// Relevance score for search ranking
    /// - Parameter query: The search query
    /// - Returns: A score combining quality and text match relevance
    func relevanceScore(for query: String) -> Double {
        guard !query.isEmpty else { return qualityScore }
        
        var score = qualityScore * 0.6 // Base weight on quality
        
        // Boost if query matches human text exactly
        if let humanText = humanText {
            let lowercasedQuery = query.lowercased()
            let lowercasedText = humanText.lowercased()
            
            if lowercasedText == lowercasedQuery {
                score += 0.4 // Exact match bonus
            } else if lowercasedText.hasPrefix(lowercasedQuery) {
                score += 0.3 // Prefix match bonus
            } else if lowercasedText.contains(lowercasedQuery) {
                score += 0.2 // Contains match bonus
            }
        }
        
        // Boost recent phrases slightly
        if let timestamp = timestamp {
            let ageInDays = Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
            if ageInDays < 7 {
                score += 0.05 // Recent content boost
            }
        }
        
        return min(score, 1.0) // Cap at 1.0
    }
    
    /// Preview text for list/grid cells
    var translationPreview: String {
        guard let translation = dogTranslation else { return "" }
        if translation.count > 100 {
            return String(translation.prefix(100)) + "..."
        }
        return translation
    }
    
    /// Full translation text or fallback
    var displayTranslation: String {
        return dogTranslation ?? "No translation available"
    }
    
    /// Human text or fallback
    var displayText: String {
        return humanText ?? "Unknown phrase"
    }
}
