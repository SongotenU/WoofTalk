import SwiftUI

struct OfflineModeView: View {
    @State private var isOffline = false
    @State private var translationHistory: [TranslationRecord] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(isOffline ? "Offline Mode" : "Online Mode").font(.title2).fontWeight(.semibold)
                    Text(isOffline ? "You're offline. Translation history is available." : "You're online. All features enabled.")
                        .font(.caption).foregroundColor(.secondary)
                }
                .padding()
                .background(isOffline ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(10)

                Toggle("Enable Offline Mode", isOn: $isOffline)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))

                if !translationHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Translation History:").font(.headline)
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(translationHistory) { record in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(record.input).font(.subheadline).foregroundColor(.primary)
                                            Spacer()
                                            Text(record.timestamp, style: .time).font(.caption).foregroundColor(.secondary)
                                        }
                                        Text("→ ").font(.caption).foregroundColor(.secondary) + Text(record.output).font(.caption).foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Offline Mode")
        }
    }
}

struct TranslationRecord: Identifiable {
    let id = UUID()
    let input: String
    let output: String
    let timestamp: Date
}
