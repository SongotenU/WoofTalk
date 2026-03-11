// AudioEngine.swift
// WoofTalk

import AVFoundation

/// The core audio engine that manages audio session configuration, capture, and playback
final class AudioEngine {
    
    // MARK: - Public Properties
    
    /// Current audio session state
    var audioSessionState: AudioSessionState = .inactive
    
    /// Latency metrics for the audio pipeline
    var latencyMetrics: LatencyMetrics = LatencyMetrics()
    
    /// Whether the engine is currently running
    var isRunning: Bool {
        audioEngine.isRunning
    }
    
    // MARK: - Private Properties
    
    private let audioEngine = AVAudioEngine()
    private let audioSessionManager = AudioSessionManager()
    private let audioCapture: AudioCapture
    private let audioPlayback: AudioPlayback
    private let speechRecognizer: SpeechRecognizer
    
    private var bufferProcessingQueue = DispatchQueue(
        label: "com.wooftalk.audio.processing",
        qos: .userInitiated
    )
    
    // MARK: - Initialization
    
    init() {
        self.audioCapture = AudioCapture(audioEngine: audioEngine)
        self.audioPlayback = AudioPlayback(audioEngine: audioEngine)
        self.speechRecognizer = SpeechRecognizer()
        
        setupAudioEngine()
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Start the audio engine with real-time processing
    func start() throws {
        try configureAudioSession()
        try startAudioEngine()
        audioSessionState = .active
    }
    
    /// Stop the audio engine and clean up resources
    func stop() {
        audioEngine.stop()
        audioSessionManager.deactivateSession()
        audioSessionState = .inactive
    }
    
    /// Process audio buffer for speech recognition
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) -> RecognitionResult? {
        let startTime = Date()
        
        // Process audio buffer through speech recognition
        let result = speechRecognizer.recognize(buffer: buffer)
        
        // Measure latency
        let processingTime = Date().timeIntervalSince(startTime)
        latencyMetrics.lastProcessingTime = processingTime
        latencyMetrics.totalProcessingTime += processingTime
        latencyMetrics.bufferCount += 1
        
        return result
    }
    
    /// Play synthesized audio for translation output
    func playTranslation(_ text: String) throws {
        try audioPlayback.play(text: text)
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine() {
        // Configure audio engine format
        let format = AudioFormat.defaultFormat
        audioEngine.inputNode.installTap(
            onBus: 0,
            bufferSize: 2048, // 5ms at 44.1kHz
            format: format
        ) { [weak self] buffer, when in
            self?.handleAudioBuffer(buffer)
        }
    }
    
    private func configureAudioSession() throws {
        try audioSessionManager.configureSession(
            category: .playAndRecord,
            options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
        )
    }
    
    private func startAudioEngine() throws {
        try audioEngine.start()
    }
    
    private func handleAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        bufferProcessingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Process buffer for speech recognition
            let recognitionResult = self.processAudioBuffer(buffer)
            
            // Handle recognition result
            if let result = recognitionResult {
                self.handleRecognitionResult(result)
            }
        }
    }
    
    private func handleRecognitionResult(_ result: RecognitionResult) {
        // This would be handled by the translation engine in S02
        // For now, we just log the result
        print("Recognition result: \(result.text)")
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    @objc private func audioRouteChanged(_ notification: Notification) {
        print("Audio route changed: \(notification.userInfo ?? [:])")
    }
}

// MARK: - Supporting Types

struct AudioSessionState: CustomStringConvertible {
    let isActive: Bool
    let category: AVAudioSession.Category?
    let categoryOptions: AVAudioSession.CategoryOptions
    
    var description: String {
        return "AudioSessionState(isActive: \(isActive), category: \(category?.rawValue ?? "none"))"
    }
    
    static let active = AudioSessionState(
        isActive: true,
        category: .playAndRecord,
        categoryOptions: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
    )
    
    static let inactive = AudioSessionState(
        isActive: false,
        category: nil,
        categoryOptions: []
    )
}

struct LatencyMetrics {
    var lastProcessingTime: TimeInterval = 0
    var totalProcessingTime: TimeInterval = 0
    var bufferCount: Int = 0
    var averageProcessingTime: TimeInterval {
        return bufferCount > 0 ? totalProcessingTime / Double(bufferCount) : 0
    }
}

struct RecognitionResult {
    let text: String
    let confidence: Float
    let timestamp: Date
    let isFinal: Bool
}

enum AudioEngineError: Error, LocalizedError {
    case audioSessionConfigurationFailed
    case audioEngineStartFailed
    case microphonePermissionDenied
    case audioRouteUnavailable
    
    var errorDescription: String? {
        switch self {
        case .audioSessionConfigurationFailed:
            return "Failed to configure audio session."
        case .audioEngineStartFailed:
            return "Failed to start audio engine."
        case .microphonePermissionDenied:
            return "Microphone permission denied."
        case .audioRouteUnavailable:
            return "No available audio route."
        }
    }
}