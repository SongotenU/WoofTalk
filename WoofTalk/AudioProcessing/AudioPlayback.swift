import AVFoundation

/// Handles audio playback for translation output with proper routing and latency
final class AudioPlayback {
    private let audioPlayer = AVAudioPlayerNode()
    private let audioEngine = AVAudioEngine()
    private var isPlaying = false

    weak var delegate: AudioPlaybackDelegate?

    init() {
        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: AudioFormats.pcmFormat)
    }

    func playAudio(_ audioData: Data) throws {
        stop()

        guard let audioBuffer = createAudioBuffer(from: audioData) else {
            throw AudioPlaybackError.invalidAudioData
        }

        audioPlayer.scheduleBuffer(audioBuffer) {
            self.delegate?.audioPlayback(self, didFinishPlaying: true)
        }

        try audioEngine.start()
        audioPlayer.play()
        isPlaying = true
        delegate?.audioPlaybackDidStart(self)
    }

    func stop() {
        guard isPlaying else { return }
        audioPlayer.stop()
        audioEngine.stop()
        isPlaying = false
        delegate?.audioPlaybackDidStop(self)
    }

    func pause() {
        guard isPlaying else { return }
        audioPlayer.pause()
        isPlaying = false
        delegate?.audioPlaybackDidPause(self)
    }

    func resume() throws {
        guard !isPlaying else { return }
        try audioEngine.start()
        audioPlayer.play()
        isPlaying = true
        delegate?.audioPlaybackDidResume(self)
    }

    var volume: Float {
        get { audioPlayer.volume }
        set {
            audioPlayer.volume = newValue
            delegate?.audioPlayback(self, didChangeVolume: newValue)
        }
    }

    var isPlayingAudio: Bool {
        isPlaying
    }

    // MARK: - Private Methods

    private func createAudioBuffer(from audioData: Data) -> AVAudioPCMBuffer? {
        let format = AudioFormats.pcmFormat
        let frameCount = AVAudioFrameCount(audioData.count) / AVAudioFrameCount(format.streamDescription.pointee.mBytesPerFrame)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount

        if let channels = buffer.floatChannelData {
            audioData.withUnsafeBytes { ptr in
                for channel in 0..<Int(format.channelCount) {
                    guard let baseAddress = ptr.bindMemory(to: Float.self).baseAddress else { return }
                    channels[channel].assign(from: baseAddress, count: Int(frameCount))
                }
            }
        }

        return buffer
    }
}

protocol AudioPlaybackDelegate: AnyObject {
    func audioPlaybackDidStart(_ playback: AudioPlayback)
    func audioPlaybackDidStop(_ playback: AudioPlayback)
    func audioPlaybackDidPause(_ playback: AudioPlayback)
    func audioPlaybackDidResume(_ playback: AudioPlayback)
    func audioPlayback(_ playback: AudioPlayback, didFinishPlaying finished: Bool)
    func audioPlayback(_ playback: AudioPlayback, didChangeVolume volume: Float)
    func audioPlayback(_ playback: AudioPlayback, didChangeOutputPort port: AVAudioSession.Port)
    func audioPlayback(_ playback: AudioPlayback, didFailWithError error: Error)
}

enum AudioPlaybackError: Error, LocalizedError {
    case invalidAudioData
    case audioEngineStartFailed
    case bufferCreationFailed
    case formatNotAvailable

    var errorDescription: String? {
        switch self {
        case .invalidAudioData:
            return "Invalid audio data"
        case .audioEngineStartFailed:
            return "Audio engine start failed"
        case .bufferCreationFailed:
            return "Audio buffer creation failed"
        case .formatNotAvailable:
            return "Audio format not available"
        }
    }
}
