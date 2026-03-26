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
    @State private var translationMode: TranslationMode = UserDefaults.standard.translationMode
    @State private var qualityScore: TranslationQualityScore?
    @StateObject private var modeManager = TranslationModeManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Translation Mode Toggle
                HStack {
                    Spacer()
                    Picker("Mode", selection: $translationMode) {
                        ForEach(TranslationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .onChange(of: translationMode) { newMode in
                        UserDefaults.standard.translationMode = newMode
                        if newMode == .ai {
                            Task { await modeManager.enableAIMode() }
                        } else {
                            modeManager.enableRuleBasedMode()
                        }
                    }
                    
                    Spacer()
                }
                
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
                
                // Quality indicator for AI mode
                if translationMode == .ai, let score = qualityScore {
                    HStack {
                        Circle()
                            .fill(qualityColor(for: score))
                            .frame(width: 10, height: 10)
                        Text("Quality: \(score.qualityTier.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.0f%%", score.confidence * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
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
            translationMode = UserDefaults.standard.translationMode
            if translationMode == .ai {
                Task { await modeManager.enableAIMode() }
            }
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
    
    private func qualityColor(for score: TranslationQualityScore) -> Color {
        switch score.qualityTier {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .orange
        case .veryLow: return .red
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            simulateAudioLevels()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let sampleInput = "Woof woof! (excited)"
                inputText = sampleInput
                translationStatus = "Translating..."
                
                let translationLatency: TimeInterval = translationMode == .ai ? 0.2 : 1.5
                currentLatency = translationLatency
                
                DispatchQueue.main.asyncAfter(deadline: .now() + translationLatency) {
                    if self.translationMode == .ai {
                        Task {
                            do {
                                let result = try await AITranslationService.shared.translate(
                                    input: sampleInput,
                                    direction: .dogToHuman
                                )
                                await MainActor.run {
                                    self.translatedText = result.translatedText
                                    self.qualityScore = result.qualityScore
                                    self.translationStatus = "Translation complete"
                                    self.isTranslating = false
                                }
                            } catch {
                                await MainActor.run {
                                    self.translatedText = "Hello! I'm happy to see you! (excited)"
                                    self.translationStatus = "Translation complete"
                                    self.isTranslating = false
                                }
                            }
                        }
                    } else {
                        translatedText = "Hello! I'm happy to see you! (excited)"
                        translationStatus = "Translation complete"
                        isTranslating = false
                    }
                    
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
    }
    
    private func clearTranslation() {
        inputText = ""
        translatedText = ""
        translationStatus = "Ready to translate"
        isRecording = false
        isTranslating = false
        currentLatency = 0
        qualityScore = nil
    }
    
    private func simulateAudioLevels() {
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