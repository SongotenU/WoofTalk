import SwiftUI

struct OfflineModeView: View {
    @State private var isOffline = false
    @State private var translationHistory: [TranslationRecord] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text(isOffline ? "Offline Mode" : "Online Mode").font(.title2).fontWeight(.semibold)
                        .accessibilityLabel(isOffline ? "Offline Mode Active" : "Online Mode Active")
                    Text(isOffline ? "You're offline. Translation history is available." : "You're online. All features enabled.")
                        .font(.caption).foregroundColor(.secondary)
                        .accessibilityLabel(isOffline ? "Offline: Translation history available" : "Online: All features enabled")
                }
                .padding()
                .background(isOffline ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(10)
                .accessibilityElement(children: .combine)

                Toggle("Enable Offline Mode", isOn: $isOffline)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .accessibilityLabel("Enable Offline Mode")
                    .accessibilityHint("Switches between online and offline mode")

                if !translationHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Translation History:").font(.headline)
                            .accessibilityLabel("Translation History")
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
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Input: \(record.input), Output: \(record.output)")
                                }
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Offline Mode")
            .accessibilityLabel("Offline Mode Settings")
        }
    }
}

struct TranslationRecord: Identifiable {
    let id = UUID()
    let input: String
    let output: String
    let timestamp: Date
}
