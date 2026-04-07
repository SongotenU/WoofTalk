import AVFoundation
import Combine

/// Manages microphone audio capture with real-time level metering.
class AudioRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0

    private var audioEngine: AVAudioEngine?
    private var node: AVAudioInputNode?

    func startRecording() throws {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try AVAudioSession.sharedInstance().setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
            self?.updateAudioLevel(from: buffer)
        }

        try engine.start()
        audioEngine = engine
        node = inputNode
        isRecording = true
    }

    func stopRecording() {
        node?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        node = nil
        isRecording = false
        audioLevel = 0.0

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {}
    }

    private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelValues = channelData[0]
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0.0
        for i in 0..<frameLength {
            let value = channelValues[i]
            sum += value * value
        }
        let rms = sqrt(sum / Float(frameLength))

        DispatchQueue.main.async {
            self.audioLevel = min(rms * 5.0, 1.0) // amplify for visual
        }
    }
}
