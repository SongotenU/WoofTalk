import AVFoundation

/// Core audio processing engine for real-time speech-to-speech translation
final class AudioEngine {
    private let audioEngine = AVAudioEngine()
    private let audioSessionManager = AudioSessionManager()
    private let audioPlayback = AudioPlayback()
    private let speechRecognizer = SpeechRecognition()
    private let barkDetector = BarkDetector()
    private let noiseProcessor = NoiseCancellationProcessor()
    private var windNoiseFilter: AVAudioUnitEQ?

    weak var delegate: AudioEngineDelegate?

    func start() throws {
        try audioSessionManager.configureSession()
        setupWindNoiseReduction()
        try audioEngine.start()
    }

    func stop() {
        audioEngine.stop()
        audioSessionManager.deactivateSession()
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        let filtered = noiseProcessor.process(buffer: buffer)
        let barkResult = barkDetector.processBuffer(filtered, at: time)
        guard barkResult.shouldTranslate else { return }
        speechRecognizer.processAudioBuffer(barkResult.buffer, at: time)
    }

    func playAudio(_ audioData: Data) throws {
        try audioPlayback.playAudio(audioData)
    }

    /// Signal-to-noise ratio for audio quality indicator
    func getSignalToNoiseRatio(of buffer: AVAudioPCMBuffer) -> Float {
        guard let floatData = buffer.floatChannelData else { return 0 }
        let frameCount = Int(buffer.frameLength)
        var signalEnergy: Float = 0
        var noiseEnergy: Float = 0

        for channel in 0..<Int(buffer.format.channelCount) {
            let samples = floatData[channel]
            vDSP_svesq(samples, 1, &signalEnergy, vDSP_Length(frameCount))
            var mean: Float = 0
            vDSP_meanv(samples, 1, &mean, vDSP_Length(frameCount))
            var noiseSamples = [Float](repeating: 0, count: frameCount)
            vDSP_vsbs(samples, 1, &mean, &noiseSamples, 1, vDSP_Length(frameCount))
            vDSP_svesq(noiseSamples, 1, &noiseEnergy, vDSP_Length(frameCount))
        }

        let snr = signalEnergy / max(noiseEnergy, 0.0001)
        return 10 * log10(snr)
    }

    // MARK: - Wind Noise Reduction

    private func setupWindNoiseReduction() {
        let eq = AVAudioUnitEQ(numberOfBands: 2)
        let highPass = eq.bands[0]
        highPass.filterType = .highPass
        highPass.frequency = 200
        highPass.bypass = false

        let lowPass = eq.bands[1]
        lowPass.filterType = .lowPass
        lowPass.frequency = 3000
        lowPass.bypass = false

        audioEngine.attach(eq)
        windNoiseFilter = eq
    }

    func enableWindNoiseReduction(_ enabled: Bool) {
        windNoiseFilter?.bypass = !enabled
    }
}

protocol AudioEngineDelegate: AnyObject {
    func audioEngine(_ engine: AudioEngine, didRecognizeSpeech text: String)
    func audioEngine(_ engine: AudioEngine, didFailWithError error: Error)
    func audioEngineDidStart(_ engine: AudioEngine)
    func audioEngineDidStop(_ engine: AudioEngine)
    func audioEngine(_ engine: AudioEngine, didUpdateSNR snr: Float)
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
