// MARK: - AudioCapture

import AVFoundation

/// Handles real-time audio capture from microphone with proper buffer management
final class AudioCapture {
    
    // MARK: Properties
    private let audioEngine = AVAudioEngine()
    private let audioFormat = AudioFormats.pcmFormat
    private var isCapturing = false
    private var bufferCount = 0
    private var totalProcessingTime: TimeInterval = 0
    
    // MARK: Delegates
    weak var delegate: AudioCaptureDelegate?
    
    // MARK: Initialization
    init() {
        setupAudioEngine()
    }
    
    // MARK: Public Methods
    func startCapture() throws {
        guard !isCapturing else { return }
        
        // Check microphone permission
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        guard permissionStatus == .granted else {
            throw AudioEngineError.microphonePermissionDenied
        }
        
        // Start audio engine
        try audioEngine.start()
        isCapturing = true
        
        // Notify delegate
        delegate?.audioCaptureDidStart(self)
    }
    
    func stopCapture() {
        guard isCapturing else { return }
        
        audioEngine.stop()
        isCapturing = false
        
        // Notify delegate
        delegate?.audioCaptureDidStop(self)
        
        // Log performance metrics
        let averageProcessingTime = bufferCount > 0 ? totalProcessingTime / Double(bufferCount) : 0
        print("AudioCapture: Processed \(bufferCount) buffers, avg processing time: \(averageProcessingTime * 1000)ms")
    }
    
    // MARK: Private Methods
    private func setupAudioEngine() {
        // Configure input node
        guard let inputNode = audioEngine.inputNode else {
            return
        }
        
        // Install tap for real-time audio capture
        let inputFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 5120, format: inputFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer, at: time)
        }
        
        // Connect input to main mixer for monitoring
        audioEngine.connect(inputNode, to: audioEngine.mainMixerNode, format: inputFormat)
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        // Measure processing time
        let startTime = CACurrentMediaTime()
        
        // Notify delegate for processing
        delegate?.audioCapture(self, didReceiveBuffer: buffer, at: time)
        
        // Calculate processing time
        let processingTime = CACurrentMediaTime() - startTime
        totalProcessingTime += processingTime
        bufferCount += 1
        
        // Log buffer statistics periodically
        if bufferCount % 100 == 0 {
            print("AudioCapture: Buffer #\(bufferCount), size: \(buffer.frameLength), processing: \(processingTime * 1000)ms")
        }
    }
    
    // MARK: Audio Information
    var currentInputFormat: AVAudioFormat? {
        return audioEngine.inputNode?.outputFormat(forBus: 0)
    }
    
    var currentSampleRate: Double {
        return currentInputFormat?.sampleRate ?? AudioFormats.standardSampleRate
    }
    
    var currentChannelCount: UInt32 {
        return currentInputFormat?.channelCount ?? 1
    }
    
    var isMicrophoneAvailable: Bool {
        return AVAudioSession.sharedInstance().isInputAvailable
    }
    
    // MARK: Audio Visualization
    func getAudioLevel() -> Float {
        guard let inputNode = audioEngine.inputNode,
              let format = currentInputFormat else {
            return 0.0
        }
        
        // Calculate RMS (Root Mean Square) level
        let channelCount = Int(format.channelCount)
        let frameLength = Int(inputNode.inputFormat(forBus: 0).sampleRate)
        
        var level: Float = 0.0
        
        for channel in 0..<channelCount {
            guard let channelData = inputNode.inputFormat(forBus: 0).channelData?[channel] else {
                continue
            }
            
            var sum: Float = 0.0
            for frame in 0..<frameLength {
                sum += channelData[frame] * channelData[frame]
            }
            
            let rms = sqrt(sum / Float(frameLength))
            level = max(level, rms)
        }
        
        return level
    }
}

// MARK: - AudioCaptureDelegate

protocol AudioCaptureDelegate: AnyObject {
    func audioCaptureDidStart(_ capture: AudioCapture)
    func audioCaptureDidStop(_ capture: AudioCapture)
    func audioCapture(_ capture: AudioCapture, didReceiveBuffer buffer: AVAudioPCMBuffer, at time: AVAudioTime)
    func audioCapture(_ capture: AudioCapture, didFailWithError error: Error)
    func audioCapture(_ capture: AudioCapture, didUpdateAudioLevel level: Float)
}

// MARK: - AudioCapture Errors

enum AudioCaptureError: Error, LocalizedError {
    case microphonePermissionDenied
    case audioEngineConfigurationFailed
    case bufferProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission denied"
        case .audioEngineConfigurationFailed:
            return "Audio engine configuration failed"
        case .bufferProcessingFailed:
            return "Audio buffer processing failed"
        }
    }
}

// MARK: - AudioCapture Extensions

extension AudioCapture {
    /// Get buffer statistics
    var bufferStatistics: (count: Int, totalProcessingTime: TimeInterval, averageProcessingTime: TimeInterval) {
        let averageTime = bufferCount > 0 ? totalProcessingTime / Double(bufferCount) : 0
        return (bufferCount, totalProcessingTime, averageTime)
    }
    
    /// Check if capture is running
    var isRunning: Bool {
        return isCapturing
    }
    
    /// Get current audio format description
    var audioFormatDescription: String {
        let format = currentInputFormat
        let sampleRate = format?.sampleRate ?? AudioFormats.standardSampleRate
        let channels = format?.channelCount ?? 1
        return String(format: "%.0f kHz, %d channels", sampleRate / 1000.0, channels)
    }
}