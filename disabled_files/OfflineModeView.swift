import SwiftUI

struct OfflineModeView: View {
    @State private var isOffline = false
    @State private var translationHistory: [TranslationRecord] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Offline status
                VStack(spacing: 8) {
                    Text(isOffline ? "Offline Mode" : "Online Mode")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(isOffline ? "You're offline. Translation history is available." : "You're online. All features enabled.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(isOffline ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(10)
                
                // Toggle offline mode
                Toggle("Enable Offline Mode", isOn: $isOffline)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                // Translation history
                if !translationHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Translation History:")
                            .font(.headline)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(translationHistory) { record in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(record.input)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            Text(record.timestamp, style: .relative)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text(record.translation)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 20)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.gray.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .frame(height: 200)
                        .cornerRadius(10)
                    }
                } else {
                    Text("No translation history yet")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Offline features info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Offline Features:")
                        .font(.headline)
                    
                    ForEach(offlineFeatures, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Offline Mode")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Load translation history
            loadHistory()
        }
    }
    
    private let offlineFeatures = [
        "View translation history",
        "Manage cached translations",
        "Access basic vocabulary",
        "No internet required"
    ]
    
    private func loadHistory() {
        // Simulate loading translation history
        translationHistory = [
            TranslationRecord(input: "Woof woof!", translation: "Hello!", timestamp: Date().addingTimeInterval(-3600)),
            TranslationRecord(input: "Arf arf!", translation: "I'm excited!", timestamp: Date().addingTimeInterval(-7200)),
            TranslationRecord(input: "Growl...", translation: "I'm angry.", timestamp: Date().addingTimeInterval(-86400))
        ]
    }
}

struct TranslationRecord: Identifiable, Equatable {
    let id = UUID()
    let input: String
    let translation: String
    let timestamp: Date
}