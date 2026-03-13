// MARK: - TranslationView

import SwiftUI

struct TranslationView: View {
    @State private var isRecording = false
    @State private var inputText = ""
    @State private var translatedText = ""
    @State private var translationStatus = "Ready to translate"
    @State private var currentLatency: TimeInterval = 0
    @State private var audioLevel: Float = 0
    @State private var isTranslating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Latency Indicator
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("Latency:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(latencyColor)
                                .frame(width: 8, height: 8)
                            
                            Text(String(format: "%.1f", currentLatency))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(latencyColor)
                            
                            Text("s")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.trailing, 16)
                
                // Status display
                VStack(spacing: 8) {
                    Text(translationStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !translatedText.isEmpty {
                        Text(translatedText)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                
                // Input display
                VStack(spacing: 8) {
                    Text("Input:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !inputText.isEmpty {
                        Text(inputText)
                            .font(.body)
                            .foregroundColor(.primary)
                    } else {
                        Text("Tap to start recording")
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Audio level indicator
                HStack {
                    Text("Audio Level:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(Color.blue.opacity(0.8))
                                .frame(width: geometry.size.width * CGFloat(audioLevel), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
                
                // Action button
                Button(action: toggleRecording) {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.largeTitle)
                        
                        Text(isRecording ? "Stop" : "Start")
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .animation(.easeInOut, value: isRecording)
                }
                .disabled(isTranslating)
                
                // Translation progress indicator
                if isTranslating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                }
                
                // Clear button
                Button("Clear") {
                    clearTranslation()
                }
                .padding(.top, 10)
                .disabled(isTranslating)
            }
            .padding()
            .navigationTitle("Dog Translator")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
            .animation(.easeInOut(duration: 0.3), value: currentLatency)
        }
        .onAppear {
            // Initialize translation engine
            TranslationEngine.shared.initialize()
        }
    }
    
    private var latencyColor: Color {
        if currentLatency < 1.0 {
            return .green
        } else if currentLatency < 2.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        translationStatus = "Listening..."
        isTranslating = true
        
        // Start audio recording (simulated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simulate audio level updates
            simulateAudioLevels()
            
            // Simulate receiving dog vocalization
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let sampleInput = "Woof woof! (excited)"
                inputText = sampleInput
                translationStatus = "Translating..."
                
                // Simulate translation with latency
                let translationLatency: TimeInterval = 1.5
                currentLatency = translationLatency
                
                DispatchQueue.main.asyncAfter(deadline: .now() + translationLatency) {
                    translatedText = "Hello! I'm happy to see you! (excited)"
                    translationStatus = "Translation complete"
                    isTranslating = false
                    
                    // Play dog vocalization
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        translationStatus = "Playing translation..."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            translationStatus = "Ready to translate"
                        }
                    }
                }
            }
        }
    }
    
    private func stopRecording() {
        translationStatus = "Ready to translate"
        isTranslating = false
        // Audio recording would stop here
    }
    
    private func clearTranslation() {
        inputText = ""
        translatedText = ""
        translationStatus = "Ready to translate"
        isRecording = false
        isTranslating = false
        currentLatency = 0
    }
    
    private func simulateAudioLevels() {
        // Simulate audio level updates
        var level: Float = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isRecording {
                level = Float.random(in: 0...1)
                audioLevel = level
            } else {
                timer.invalidate()
                audioLevel = 0
            }
        }
    }
}

struct TranslationView_Previews: PreviewProvider {
    static var previews: some View {
        TranslationView()
    }
}