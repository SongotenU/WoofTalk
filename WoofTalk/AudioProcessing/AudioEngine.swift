import AVFoundation

/// Core audio processing engine for real-time speech-to-speech translation
final class AudioEngine {
    private let audioEngine = AVAudioEngine()
    private let audioSessionManager = AudioSessionManager()
    private let audioPlayback = AudioPlayback()
    private let speechRecognizer = SpeechRecognition()

    func start() throws {
        try audioSessionManager.configureSession()
        try audioEngine.start()
    }

    func stop() {
        audioEngine.stop()
        audioSessionManager.deactivateSession()
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        speechRecognizer.processAudioBuffer(buffer, at: time)
    }

    func playAudio(_ audioData: Data) throws {
        try audioPlayback.playAudio(audioData)
    }
}

protocol AudioEngineDelegate: AnyObject {
    func audioEngine(_ engine: AudioEngine, didRecognizeSpeech text: String)
    func audioEngine(_ engine: AudioEngine, didFailWithError error: Error)
    func audioEngineDidStart(_ engine: AudioEngine)
    func audioEngineDidStop(_ engine: AudioEngine)
}

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
