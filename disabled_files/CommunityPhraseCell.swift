// MARK: - CommunityPhraseCell

import SwiftUI

struct CommunityPhraseCell: View {
    let phrase: CommunityPhrase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(phrase.displayText)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                QualityBadge(score: phrase.qualityScore)
            }
            
            Text(phrase.translationPreview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "person.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(phrase.contributorDisplay)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(phrase.ageDisplayString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct QualityBadge: View {
    let score: Double
    
    var body: some View {
        Text("\(Int(score * 100))%")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(qualityColor.opacity(0.2))
            .foregroundColor(qualityColor)
            .cornerRadius(8)
    }
    
    private var qualityColor: Color {
        switch score {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
}
