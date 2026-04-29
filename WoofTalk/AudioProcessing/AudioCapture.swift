import AVFoundation

/// Handles real-time audio capture from microphone with proper buffer management
final class AudioCapture {
    private let audioEngine = AVAudioEngine()
    private var isCapturing = false

    weak var delegate: AudioCaptureDelegate?

    init() {
        setupAudioEngine()
    }

    func startCapture() throws {
        guard !isCapturing else { return }

        guard AVAudioSession.sharedInstance().recordPermission == .granted else {
            throw AudioEngineError.microphonePermissionDenied
        }

        try audioEngine.start()
        isCapturing = true
        delegate?.audioCaptureDidStart(self)
    }

    func stopCapture() {
        guard isCapturing else { return }
        audioEngine.stop()
        isCapturing = false
        delegate?.audioCaptureDidStop(self)
    }

    var currentInputFormat: AVAudioFormat? {
        audioEngine.inputNode?.outputFormat(forBus: 0)
    }

    var currentSampleRate: Double {
        currentInputFormat?.sampleRate ?? AudioFormats.standardSampleRate
    }

    var currentChannelCount: UInt32 {
        currentInputFormat?.channelCount ?? 1
    }

    var isMicrophoneAvailable: Bool {
        AVAudioSession.sharedInstance().isInputAvailable
    }

    private func setupAudioEngine() {
        guard let inputNode = audioEngine.inputNode else {
            return
        }

        let inputFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 5120, format: inputFormat) { [weak self] buffer, time in
            self?.delegate?.audioCapture(self!, didReceiveBuffer: buffer, at: time)
        }

        audioEngine.connect(inputNode, to: audioEngine.mainMixerNode, format: inputFormat)
    }
}

protocol AudioCaptureDelegate: AnyObject {
    func audioCaptureDidStart(_ capture: AudioCapture)
    func audioCaptureDidStop(_ capture: AudioCapture)
    func audioCapture(_ capture: AudioCapture, didReceiveBuffer buffer: AVAudioPCMBuffer, at time: AVAudioTime)
    func audioCapture(_ capture: AudioCapture, didFailWithError error: Error)
    func audioCapture(_ capture: AudioCapture, didUpdateAudioLevel level: Float)
}

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
