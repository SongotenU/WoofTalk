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

                QualityBadge(phrase: phrase)
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
    let phrase: CommunityPhrase

    var body: some View {
        Text(phrase.qualityScoreFormatted)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(phrase.qualityColor.opacity(0.2))
            .foregroundColor(phrase.qualityColor)
            .cornerRadius(8)
    }
}
