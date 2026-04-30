// MARK: - CommunityPhrase Extensions

import Foundation
import SwiftUI

enum SortOption: String, CaseIterable {
    case quality = "Quality"
    case date = "Date"
    case relevance = "Relevance"
}

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
    
    /// Shared quality color for UI (used by QualityBadge, DetailView, etc.)
    var qualityColor: Color {
        return qualityTier.color
    }

    /// Display text for submitter
    var contributorDisplay: String {
        return submitter?.username ?? "Anonymous"
    }
    
    /// Human-readable age string (e.g., "3 days ago", "2 hours ago")
    var ageDisplayString: String {
        guard let timestamp else { return "Unknown" }
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: timestamp, to: Date())
        if let days = components.day {
            if days > 30 { return ">1 month ago" }
            if days > 0 { return "\(days) day\(days == 1 ? "" : "s") ago" }
        }
        if let hours = components.hour, hours > 0 { return "\(hours) hour\(hours == 1 ? "" : "s") ago" }
        return "\(components.minute ?? 0) min ago"
    }
    
    /// Relevance score combining quality and text match for search ranking
    func relevanceScore(for query: String) -> Double {
        guard !query.isEmpty else { return qualityScore }

        var score = qualityScore * 0.6

        if let humanText = humanText {
            let lowercasedQuery = query.lowercased()
            let lowercasedText = humanText.lowercased()

            if lowercasedText == lowercasedQuery {
                score += 0.4
            } else if lowercasedText.hasPrefix(lowercasedQuery) {
                score += 0.3
            } else if lowercasedText.contains(lowercasedQuery) {
                score += 0.2
            }
        }

        if ageInDays < 7 { score += 0.05 }

        return min(score, 1.0)
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
