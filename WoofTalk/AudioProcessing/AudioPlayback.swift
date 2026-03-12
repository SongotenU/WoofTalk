// MARK: - AudioPlayback

import AVFoundation

/// Handles audio playback for translation output with proper routing and latency
final class AudioPlayback {
    
    // MARK: Properties
    private let audioPlayer = AVAudioPlayerNode()
    private let audioEngine = AVAudioEngine()
    private var isPlaying = false
    private var currentAudioData: Data?
    
    // MARK: Delegates
    weak var delegate: AudioPlaybackDelegate?
    
    // MARK: Initialization
    init() {
        setupAudioEngine()
    }
    
    // MARK: Public Methods
    func playAudio(_ audioData: Data) throws {
        // Stop any currently playing audio
        stop()
        
        // Store audio data
        currentAudioData = audioData
        
        // Create audio buffer from data
        guard let audioBuffer = createAudioBuffer(from: audioData) else {
            throw AudioPlaybackError.invalidAudioData
        }
        
        // Schedule playback
        audioPlayer.scheduleBuffer(audioBuffer) {
            self.delegate?.audioPlayback(self, didFinishPlaying: true)
        }
        
        // Start playback
        try audioEngine.start()
        audioPlayer.play()
        isPlaying = true
        
        // Notify delegate
        delegate?.audioPlaybackDidStart(self)
    }
    
    func stop() {
        guard isPlaying else { return }
        
        audioPlayer.stop()
        audioEngine.stop()
        isPlaying = false
        
        // Notify delegate
        delegate?.audioPlaybackDidStop(self)
    }
    
    func pause() {
        guard isPlaying else { return }
        
        audioPlayer.pause()
        isPlaying = false
        
        // Notify delegate
        delegate?.audioPlaybackDidPause(self)
    }
    
    func resume() throws {
        guard !isPlaying else { return }
        
        try audioEngine.start()
        audioPlayer.play()
        isPlaying = true
        
        // Notify delegate
        delegate?.audioPlaybackDidResume(self)
    }
    
    // MARK: Volume Control
    func setVolume(_ volume: Float) {
        audioPlayer.volume = volume
        delegate?.audioPlayback(self, didChangeVolume: volume)
    }
    
    var volume: Float {
        get { return audioPlayer.volume }
        set { setVolume(newValue) }
    }
    
    // MARK: Audio Routing
    func setOutput(to port: AVAudioSession.Port) throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        // Get available inputs
        guard let availableInputs = audioSession.availableInputs else {
            throw AudioPlaybackError.noAvailableOutputs
        }
        
        // Find matching input
        guard let selectedInput = availableInputs.first(where: { $0.portType == port }) else {
            throw AudioPlaybackError.invalidOutputPort
        }
        
        // Set preferred input
        try audioSession.setPreferredInput(selectedInput)
        delegate?.audioPlayback(self, didChangeOutputPort: port)
    }
    
    var currentOutputPort: AVAudioSession.Port? {
        return AVAudioSession.sharedInstance().preferredInput?.portType
    }
    
    // MARK: Audio Information
    var isPlayingAudio: Bool {
        return isPlaying
    }
    
    var currentAudioDuration: TimeInterval? {
        guard let audioData = currentAudioData,
              let format = AudioFormats.pcmFormat else {
            return nil
        }
        
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(audioData.count / (format.streamDescription.pointee.mBytesPerFrame))
        return Double(frameCount) / sampleRate
    }
    
    // MARK: Private Methods
    private func setupAudioEngine() {
        // Connect audio player to main mixer
        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: AudioFormats.pcmFormat)
    }
    
    private func createAudioBuffer(from audioData: Data) -> AVAudioPCMBuffer? {
        guard let format = AudioFormats.pcmFormat else { return nil }
        
        let frameCount = AVAudioFrameCount(audioData.count / (format.streamDescription.pointee.mBytesPerFrame))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        // Copy audio data to buffer
        buffer.frameLength = frameCount
        
        // Copy data to buffer (simplified - in practice you'd need proper format handling)
        if let channels = buffer.floatChannelData {
            for channel in 0..<Int(format.channelCount) {
                let channelData = audioData.withUnsafeBytes { ptr in
                    ptr.bindMemory(to: Float.self).baseAddress?.advanced(by: channel * Int(frameCount))
                }
                channels[channel].assign(from: channelData!, count: Int(frameCount))
            }
        }
        
        return buffer
    }
    
    // MARK: Audio Synthesis
    func synthesizeTone(frequency: Double, duration: TimeInterval, amplitude: Float = 0.5) throws -> Data {
        guard let format = AudioFormats.pcmFormat else {
            throw AudioPlaybackError.formatNotAvailable
        }
        
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        // Create audio buffer for tone
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioPlaybackError.bufferCreationFailed
        }
        
        // Generate sine wave
        let channelCount = Int(format.channelCount)
        let phaseIncrement = Float(2.0 * Double.pi * frequency / sampleRate)
        
        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            var phase: Float = 0
            
            for frame in 0..<Int(frameCount) {
                let sample = sin(phase) * amplitude
                channelData[frame] = sample
                phase += phaseIncrement
            }
        }
        
        buffer.frameLength = frameCount
        
        // Convert buffer to data
        return bufferToData(buffer)
    }
    
    func synthesizeSpeech(from text: String, voice: AVSpeechSynthesisVoice? = nil) throws -> Data {
        // Use AVSpeechSynthesizer for text-to-speech
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        
        // Create audio session for speech synthesis
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback)
        try audioSession.setActive(true)
        
        // Synthesize speech
        let synthesizer = AVSpeechSynthesizer()
        
        // This would need proper audio capture implementation
        // For now, return empty data as placeholder
        return Data()
    }
    
    // MARK: Utility Methods
    private func bufferToData(_ buffer: AVAudioPCMBuffer) -> Data {
        guard let format = buffer.format else { return Data() }
        
        let channelCount = Int(format.channelCount)
        let frameCount = Int(buffer.frameLength)
        let bytesPerFrame = format.streamDescription.pointee.mBytesPerFrame
        
        var data = Data(capacity: frameCount * channelCount * Int(bytesPerFrame))
        
        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            
            for frame in 0..<frameCount {
                let sample = channelData[frame]
                // Convert float to appropriate format (simplified)
                let sampleData = Data(bytes: &sample, count: MemoryLayout<Float>.size)
                data.append(sampleData)
            }
        }
        
        return data
    }
}

// MARK: - AudioPlaybackDelegate

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

// MARK: - AudioPlayback Errors

enum AudioPlaybackError: Error, LocalizedError {
    case invalidAudioData
    case audioEngineStartFailed
    case bufferCreationFailed
    case formatNotAvailable
    case noAvailableOutputs
    case invalidOutputPort
    
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
        case .noAvailableOutputs:
            return "No available audio outputs"
        case .invalidOutputPort:
            return "Invalid audio output port"
        }
    }
}

// MARK: - AudioPlayback Extensions

extension AudioPlayback {
    /// Get playback statistics
    var playbackStatistics: (totalPlayTime: TimeInterval, averageLatency: TimeInterval) {
        // This would need actual implementation
        return (0, 0)
    }
    
    /// Check if playback is active
    var isActive: Bool {
        return isPlaying
    }
    
    /// Get current playback position
    var currentPlaybackPosition: TimeInterval? {
        guard let audioData = currentAudioData,
              let format = AudioFormats.pcmFormat else {
            return nil
        }
        
        let sampleRate = format.sampleRate
        // This would need actual implementation
        return nil
    }
}