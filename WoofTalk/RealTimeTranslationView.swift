import SwiftUI

struct RealTimeTranslationView: View {
    @State private var isTranslating = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Real-Time Translation")
                .font(.headline)

            Text(isTranslating ? "Translating..." : "Ready")
                .font(.subheadline)
                .foregroundColor(isTranslating ? .green : .secondary)

            Toggle("Continuous Mode", isOn: .constant(false))
                .toggleStyle(SwitchToggleStyle(tint: .blue))

            HStack(spacing: 16) {
                Button(action: { isTranslating = true }) {
                    Label("Start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isTranslating)

                Button(action: { isTranslating = false }) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isTranslating)
            }
        }
        .padding()
    }
}

#Preview {
    RealTimeTranslationView()
}
