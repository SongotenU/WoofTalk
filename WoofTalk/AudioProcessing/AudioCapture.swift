import AVFoundation
import Accelerate

/// Handles real-time audio capture from microphone with proper buffer management
final class AudioCapture {
    private let audioEngine = AVAudioEngine()
    private var isCapturing = false
    private let noiseProcessor = NoiseCancellationProcessor()
    private let barkDetector = BarkDetector()

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

    /// Audio level for quality indicator display
    var currentAudioLevel: Float {
        guard let buffer = currentInputFormat.flatMap({
            AVAudioPCMBuffer(pcmFormat: $0, frameCapacity: 512)
        }) else { return 0 }
        audioEngine.inputNode?.render(to: buffer, frameCount: 512, time: nil)
        return computeRMS(buffer)
    }

    /// Import audio file (MP3, WAV, M4A) and return PCM buffer
    func importAudioFile(from url: URL) throws -> AVAudioPCMBuffer {
        let asset = AVAsset(url: url)
        guard let track = asset.tracks(withMediaType: .audio).first else {
            throw AudioCaptureError.fileImportFailed
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: AudioFormats.standardSampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: true
        ]

        let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        reader.add(readerOutput)
        reader.startReading()

        var samples: [Float] = []
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                let length = CMBlockBufferGetDataLength(blockBuffer)
                var data = [UInt8](repeating: 0, count: length)
                CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: &data)
                let floatCount = length / MemoryLayout<Float>.size
                data.withUnsafeBytes { ptr in
                    if let floatPtr = ptr.bindMemory(to: Float.self).baseAddress {
                        samples.append(contentsOf: Array(UnsafeBufferPointer(start: floatPtr, count: floatCount)))
                    }
                }
            }
            CMSampleBufferInvalidate(sampleBuffer)
        }

        guard reader.status == .completed, !samples.isEmpty else {
            throw AudioCaptureError.fileImportFailed
        }

        let format = AVAudioFormat(
            standardFormatWithSampleRate: AudioFormats.standardSampleRate,
            channels: 1
        )!
        let frameCount = AVAudioFrameCount(samples.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioCaptureError.bufferCreationFailed
        }
        buffer.frameLength = frameCount
        samples.withUnsafeBufferPointer { ptr in
            buffer.floatChannelData?[0].update(from: ptr.baseAddress!, count: samples.count)
        }

        return buffer
    }

    // MARK: - Private

    private func setupAudioEngine() {
        guard let inputNode = audioEngine.inputNode else {
            return
        }

        let inputFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 5120, format: inputFormat) { [weak self] buffer, time in
            guard let self else { return }
            let level = self.computeRMS(buffer)
            self.delegate?.audioCapture(self, didUpdateAudioLevel: level)
            let filtered = self.noiseProcessor.process(buffer: buffer)
            let barkResult = self.barkDetector.processBuffer(filtered, at: time)
            guard barkResult.shouldTranslate else { return }
            self.delegate?.audioCapture(self, didReceiveBuffer: filtered, at: time)
        }

        audioEngine.connect(inputNode, to: audioEngine.mainMixerNode, format: inputFormat)
    }

    private func computeRMS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let floatData = buffer.floatChannelData else { return 0 }
        let frameCount = Int(buffer.frameLength)
        var sum: Float = 0
        vDSP_svesq(floatData[0], 1, &sum, vDSP_Length(frameCount))
        return sqrt(sum / Float(frameCount))
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
    case fileImportFailed
    case bufferCreationFailed

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission denied"
        case .audioEngineConfigurationFailed:
            return "Audio engine configuration failed"
        case .bufferProcessingFailed:
            return "Audio buffer processing failed"
        case .fileImportFailed:
            return "Failed to import audio file"
        case .bufferCreationFailed:
            return "Audio buffer creation failed"
        }
    }
}
