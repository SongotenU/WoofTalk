// MARK: - AudioEngine

import AVFoundation

/// Core audio processing engine for real-time speech-to-speech translation
final class AudioEngine {
    
    // MARK: Properties
    private let audioEngine = AVAudioEngine()
    private let audioSessionManager = AudioSessionManager()
    private let audioCapture = AudioCapture()
    private let audioPlayback = AudioPlayback()
    private let speechRecognizer = SpeechRecognition()
    
    // MARK: Initialization
    init() {
        setupAudioEngine()
    }
    
    // MARK: Public Methods
    func start() throws {
        try audioSessionManager.configureSession()
        try audioEngine.start()
        audioCapture.startCapture()
    }
    
    func stop() {
        audioEngine.stop()
        audioCapture.stopCapture()
        audioSessionManager.deactivateSession()
    }
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        // Process audio buffer for speech recognition
        speechRecognizer.processAudioBuffer(buffer, at: time)
    }
    
    func playAudio(_ audioData: Data) throws {
        try audioPlayback.playAudio(audioData)
    }
    
    // MARK: Private Methods
    private func setupAudioEngine() {
        // Configure audio engine for low-latency processing
        audioEngine.mainMixerNode.volume = 0.0
        
        // Set up audio format
        let format = AudioFormats.pcmFormat
        
        // Connect audio nodes for real-time processing
        if let inputNode = audioEngine.inputNode {
            let inputFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 5120, format: inputFormat) { [weak self] (buffer, time) in
                self?.processAudioBuffer(buffer, at: time)
            }
        }
        
        // Connect to output for monitoring
        audioEngine.connect(audioEngine.inputNode!, to: audioEngine.mainMixerNode, format: format)
    }
}

// MARK: - AudioEngineDelegate

protocol AudioEngineDelegate: AnyObject {
    func audioEngine(_ engine: AudioEngine, didRecognizeSpeech text: String)
    func audioEngine(_ engine: AudioEngine, didFailWithError error: Error)
    func audioEngineDidStart(_ engine: AudioEngine)
    func audioEngineDidStop(_ engine: AudioEngine)
}

// MARK: - AudioEngine Errors

enum AudioEngineError: Error, LocalizedError {
    case audioSessionConfigurationFailed
    case audioEngineStartFailed
    case microphonePermissionDenied
    case speechRecognitionFailed
    
    var errorDescription: String? {
        switch self {
        case .audioSessionConfigurationFailed:
            return "Failed to configure audio session"
        case .audioEngineStartFailed:
            return "Failed to start audio engine"
        case .microphonePermissionDenied:
            return "Microphone permission denied"
        case .speechRecognitionFailed:
            return "Speech recognition failed"
        }
    }
}