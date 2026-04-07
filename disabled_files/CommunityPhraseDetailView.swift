// MARK: - CommunityPhraseDetailView

import SwiftUI

struct CommunityPhraseDetailView: View {
    let phrase: CommunityPhrase
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isCopied = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("English")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(phrase.displayText)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dog Translation")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text(phrase.displayTranslation)
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Button(action: copyTranslation) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quality Metrics")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        QualityMetricView(
                            title: "Score",
                            value: phrase.qualityScoreFormatted,
                            color: qualityColor
                        )
                        
                        QualityMetricView(
                            title: "Uses",
                            value: "\(phrase.usageCount)",
                            color: .blue
                        )
                        
                        QualityMetricView(
                            title: "Age",
                            value: phrase.ageDisplayString,
                            color: .secondary
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quality: \(phrase.qualityScoreFormatted)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(qualityColor)
                                    .frame(width: geometry.size.width * CGFloat(phrase.qualityScore), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contributor")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(contributorInitial)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(phrase.contributorDisplay)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let timestamp = phrase.timestamp {
                                Text("Submitted \(timestamp, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if let direction = phrase.direction {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Translation Direction")
                            .font(.headline)
                        
                        Text(direction)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Phrase Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    private var qualityColor: Color {
        switch phrase.qualityScore {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
    
    private var contributorInitial: String {
        let name = phrase.contributorDisplay
        return String(name.prefix(1)).uppercased()
    }
    
    private func copyTranslation() {
        if let translation = phrase.dogTranslation {
            #if os(iOS)
            UIPasteboard.general.string = translation
            #endif
            isCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isCopied = false
            }
        }
    }
}

struct QualityMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
