import SwiftUI

// MARK: - LanguageSelectionView

struct LanguageSelectionView: View {
    @StateObject private var viewModel = LanguageSelectionViewModel()
    @Binding var selectedLanguage: AnimalLanguage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current Language")) {
                    ForEach(AnimalLanguage.allCases, id: \.self) { language in
                        LanguageRowView(
                            language: language,
                            isSelected: selectedLanguage == language
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLanguage = language
                            viewModel.selectLanguage(language)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Multi-language Support")
                            .font(.headline)
                        Text("Choose which animal language you want to translate. Each language has unique vocalizations and behaviors.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Language")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// MARK: - LanguageRowView

struct LanguageRowView: View {
    let language: AnimalLanguage
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(language.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(language.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text(language.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - LanguageSelectionViewModel

final class LanguageSelectionViewModel: ObservableObject {
    private let routingService = LanguageRoutingService.shared
    
    @Published var currentLanguage: AnimalLanguage
    @Published var availableLanguages: [LanguageMetadata] = []
    @Published var recentLanguages: [AnimalLanguage] = []
    @Published var isAutoDetectionEnabled: Bool = false
    
    init() {
        self.currentLanguage = routingService.currentLanguage
        self.isAutoDetectionEnabled = routingService.isAutoDetectionEnabled
        loadLanguages()
    }
    
    func loadLanguages() {
        availableLanguages = routingService.getAvailableLanguages()
        recentLanguages = LanguageStorageManager.shared.recentLanguages
    }
    
    func selectLanguage(_ language: AnimalLanguage) {
        routingService.setLanguage(language)
        currentLanguage = language
    }
    
    func toggleAutoDetection() {
        routingService.isAutoDetectionEnabled.toggle()
        isAutoDetectionEnabled = routingService.isAutoDetectionEnabled
    }
}

// MARK: - LanguageInfoCard

struct LanguageInfoCard: View {
    let language: AnimalLanguage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(language.emoji)
                    .font(.largeTitle)
                
                VStack(alignment: .leading) {
                    Text(language.displayName)
                        .font(.headline)
                    
                    Text("\(language.vocalizationPatterns.count) vocalizations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(language.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageSelectionView(selectedLanguage: .constant(.dog))
    }
}
