import SwiftUI

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: AnimalLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current Language")) {
                    ForEach(AnimalLanguage.allCases, id: \.self) { language in
                        LanguageRowView(language: language, isSelected: selectedLanguage == language)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedLanguage = language }
                    }
                }

                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Multi-language Support").font(.headline)
                        Text("Choose which animal language you want to translate. Each language has unique vocalizations and behaviors.")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Language")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

struct LanguageRowView: View {
    let language: AnimalLanguage
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(language.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(language.displayName)
                Text(language.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}
