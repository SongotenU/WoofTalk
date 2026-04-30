// MARK: - CommunityPhraseCell

import SwiftUI

struct CommunityPhraseCell: View {
    let phrase: CommunityPhrase

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if phrase.hasPhoto {
                    Image(systemName: "photo.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                }
                Text(phrase.displayText)
                    .font(.headline)
                    .lineLimit(1)
                    .accessibilityLabel("Phrase: \(phrase.displayText)")

                Spacer()

                QualityBadge(phrase: phrase)
            }

            Text(phrase.translationPreview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .accessibilityLabel("Translation: \(phrase.translationPreview)")

            if phrase.hasReactions, let top = phrase.topReactions, !top.isEmpty {
                HStack(spacing: 4) {
                    ForEach(top.prefix(3), id: \.emoji) { item in
                        Text("\(item.emoji) \(item.count)")
                            .font(.system(size: 10))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    }
                }
                .accessibilityLabel("Reactions: \(top.prefix(3).map { "\($0.emoji) \($0.count)" }.joined(separator: ", "))")
            }

            HStack {
                Image(systemName: "person.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                Text(phrase.contributorDisplay)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Contributor: \(phrase.contributorDisplay)")

                Spacer()

                Text(phrase.ageDisplayString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Posted: \(phrase.ageDisplayString)")
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
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
            .accessibilityLabel("Quality score: \(phrase.qualityScoreFormatted)")
            .accessibilityHint("Quality rating for this phrase")
    }
}
