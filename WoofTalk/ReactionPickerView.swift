import SwiftUI

struct ReactionPickerView: View {
    let phrase: CommunityPhrase
    @Environment(\.managedObjectContext) private var viewContext
    @State private var reactions: [(emoji: String, count: Int)] = []
    @State private var showingAllReactions = false

    let quickEmojis = ["🐾", "🎾", "🦴", "❤️", "👏", "🔥"]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(quickEmojis, id: \.self) { emoji in
                Button(action: { addReaction(emoji) }) {
                    VStack(spacing: 2) {
                        Text(emoji).font(.title3)
                        if let count = reactionCount(emoji), count > 0 {
                            Text("\(count)").font(.system(size: 10)).foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(reactionCount(emoji) ?? 0 > 0 ? Color.accentColor.opacity(0.15) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .onAppear { loadReactions() }
    }

    private func addReaction(_ emoji: String) {
        do {
            try phrase.addReaction(emoji, context: viewContext)
            loadReactions()
        } catch { }
    }

    private func reactionCount(_ emoji: String) -> Int? {
        reactions.first { $0.emoji == emoji }?.count
    }

    private func loadReactions() {
        reactions = phrase.topReactions
    }
}

// MARK: - CommunityPhraseCell Extensions for Photo + Reactions

extension CommunityPhrase {
    var hasPhoto: Bool { photoData != nil }
    var hasReactions: Bool { (reactions ?? [:]).isEmpty == false }
}
