import SwiftUI

struct RealTimeTranslationView: View {
    @StateObject private var viewModel = RealTimeTranslationViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            headerSection
            
            latencyDisplay
            
            audioLevelIndicator
            
            continuousModeToggle
            
            translationProgress
            
            actionButtons
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Real-Time Translation")
                    .font(.headline)
                
                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(viewModel.statusColor)
                .frame(width: 12, height: 12)
        }
    }
    
    private var latencyDisplay: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Latency:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.2fs", viewModel.currentLatency))
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.latencyColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.latencyColor)
                        .frame(width: geometry.size.width * viewModel.latencyProgress, height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("Target: <1s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Average: \(String(format: "%.2fs", viewModel.averageLatency))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var audioLevelIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(.secondary)
                
                Text("Audio Input")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [.green, .yellow, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * CGFloat(min(viewModel.audioLevel, 1.0)), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var continuousModeToggle: some View {
        Toggle(isOn: $viewModel.isContinuousMode) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(viewModel.isContinuousMode ? .blue : .secondary)
                
                Text("Continuous Mode")
                    .font(.subheadline)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .blue))
        .onChange(of: viewModel.isContinuousMode) { newValue in
            viewModel.setContinuousMode(newValue)
        }
    }
    
    private var translationProgress: some View {
        VStack(spacing: 8) {
            if viewModel.isTranslating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Translating...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(viewModel.translationCount) translations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !viewModel.partialTranslation.isEmpty {
                HStack {
                    Text("Partial:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.partialTranslation)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: viewModel.startTranslation) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.isTranslating)
            
            Button(action: viewModel.stopTranslation) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.isTranslating)
        }
    }
}

@MainActor
final class RealTimeTranslationViewModel: ObservableObject {
    @Published var isTranslating = false
    @Published var currentLatency: TimeInterval = 0
    @Published var averageLatency: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var isContinuousMode = false
    @Published var partialTranslation = ""
    @Published var translationCount = 0
    @Published var statusText = "Ready"
    
    private var controller: RealTranslationController?
    private let aiService = AITranslationService.shared
    
    var statusColor: Color {
        if isTranslating {
            return .green
        }
        return .gray
    }
    
    var latencyColor: Color {
        if currentLatency < 1.0 {
            return .green
        } else if currentLatency < 2.0 {
            return .yellow
        } else {
            return .red
        }
    }
    
    var latencyProgress: CGFloat {
        CGFloat(min(currentLatency / 3.0, 1.0))
    }
    
    func startTranslation() {
        isTranslating = true
        statusText = "Translating..."
    }
    
    func stopTranslation() {
        isTranslating = false
        statusText = "Stopped"
    }
    
    func setContinuousMode(_ enabled: Bool) {
        isContinuousMode = enabled
    }
    
    func updateLatency(_ latency: TimeInterval) {
        currentLatency = latency
        
        if translationCount > 0 {
            averageLatency = (averageLatency * Double(translationCount - 1) + latency) / Double(translationCount)
        } else {
            averageLatency = latency
        }
    }
    
    func updateAudioLevel(_ level: Float) {
        audioLevel = level
    }
}

#Preview {
    RealTimeTranslationView()
}
