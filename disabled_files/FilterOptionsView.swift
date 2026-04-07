// MARK: - FilterOptionsView

import SwiftUI

struct FilterOptionsView: View {
    @Binding var selectedQuality: Double?
    @Binding var selectedSort: SortOption
    
    private let qualityOptions: [(String, Double?)] = [
        ("All", nil),
        ("Excellent (90%+)", 0.9),
        ("Good (70%+)", 0.7),
        ("Fair (50%+)", 0.5)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Minimum Quality")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(qualityOptions, id: \.0) { option in
                            QualityFilterChip(
                                title: option.0,
                                isSelected: selectedQuality == option.1
                            ) {
                                withAnimation {
                                    selectedQuality = option.1
                                }
                            }
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Sort By")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    SortOptionButton(
                        title: "Quality",
                        icon: "star.fill",
                        isSelected: selectedSort == .quality
                    ) {
                        selectedSort = .quality
                    }
                    
                    SortOptionButton(
                        title: "Recent",
                        icon: "clock.fill",
                        isSelected: selectedSort == .date
                    ) {
                        selectedSort = .date
                    }
                    
                    SortOptionButton(
                        title: "Relevance",
                        icon: "sparkles",
                        isSelected: selectedSort == .relevance
                    ) {
                        selectedSort = .relevance
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QualityFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct SortOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}
