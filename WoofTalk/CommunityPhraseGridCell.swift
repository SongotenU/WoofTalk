// MARK: - CommunityPhraseGridCell

import SwiftUI

struct CommunityPhraseGridCell: View {
    let phrase: CommunityPhrase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Spacer()
                QualityBadge(score: phrase.qualityScore)
            }
            
            Text(phrase.displayText)
                .font(.headline)
                .lineLimit(2)
                .frame(height: 50, alignment: .topLeading)
            
            Spacer()
            
            Text(phrase.translationPreview)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.caption2)
                Text(phrase.contributorDisplay)
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(height: 160)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
