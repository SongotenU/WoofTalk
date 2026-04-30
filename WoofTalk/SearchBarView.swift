// MARK: - SearchBarView

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var onSearch: () -> Void
    var placeholder: String = "Search phrases..."
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .onSubmit {
                        onSearch()
                    }
                    .onChange(of: text) { _, newValue in
                        CommunityPhraseSearchService.shared.searchDebounced(query: newValue)
                    }
                    .accessibilityLabel("Search field")
                    .accessibilityHint("Enter search text")

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        onSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                    .accessibilityHint("Clears search text")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            if isFocused {
                Button("Cancel") {
                    text = ""
                    isFocused = false
                    onSearch()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .accessibilityLabel("Cancel search")
                .accessibilityHint("Cancels search and dismisses keyboard")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .accessibilityElement(children: .combine)
    }
}
