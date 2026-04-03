import Foundation
import AVFoundation

protocol AudioRecorderDelegate: AnyObject {
    func audioRecorder(_ recorder: AudioRecorder, didCapture buffer: AVAudioPCMBuffer)
}

extension Notification.Name {
    static let audioBufferCaptured = Notification.Name("AudioBufferCaptured")
}

actor AudioRecorder {
    static let shared = AudioRecorder()
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private let sampleRate: Double = 48000
    private let bufferSize: AVAudioFrameCount = 1024
    private var isRunning = false

    weak var delegate: AudioRecorderDelegate?

    private init() {}

    func start() throws {
        guard !isRunning else { return }

        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode

        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) {
            [weak self] buffer, time in
            Task { await self?.processBuffer(buffer) }
        }

        try audioEngine.start()
        self.audioEngine = audioEngine
        self.inputNode = inputNode
        self.isRunning = true

        print("AudioRecorder started with bufferSize=\(bufferSize) @ \(sampleRate)Hz")
    }

    func stop() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        isRunning = false
    }

    nonisolated private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        // Broadcast buffer via NotificationCenter for loose coupling
        NotificationCenter.default.post(
            name: .audioBufferCaptured,
            object: self,
            userInfo: ["buffer": buffer]
        )
    }
}
