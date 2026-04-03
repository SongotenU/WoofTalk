import Foundation
import AVFoundation
import RealityKit

actor SpatialAudioController {
    static let shared = SpatialAudioController()
    private var audioEngine: AVAudioEngine?
    private var environmentNode: AVAudioEnvironmentNode?
    private var activeNodes: [AVAudioNode] = []

    private init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        let environment = AVAudioEnvironmentNode()

        environment.renderingAlgorithm = .HRTF
        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)

        engine.attach(environment)
        engine.connect(engine.mainMixerNode, to: environment, format: nil)
        engine.connect(environment, to: engine.outputNode, format: nil)

        self.audioEngine = engine
        self.environmentNode = environment

        do {
            try engine.start()
            print("SpatialAudioController: engine started")
        } catch {
            print("ERROR: Failed to start audio engine: \(error)")
        }
    }

    func playAudio(at position: SIMD3<Float>, soundFile: String? = nil, completion: (() -> Void)? = nil) {
        guard let engine = audioEngine,
              let environment = environmentNode else {
            print("ERROR: Audio engine not ready")
            completion?()
            return
        }

        // Load audio file or generate placeholder tone
        let audioFile: AVAudioFile?
        if let soundFile = soundFile,
           let url = Bundle.main.url(forResource: soundFile, withExtension: "mp3") {
            audioFile = try? AVAudioFile(forReading: url)
        } else {
            audioFile = generatePlaceholderTone()
        }

        guard let file = audioFile else {
            print("ERROR: Could not load audio file")
            completion?()
            return
        }

        let playerNode = AVAudioPlayerNode()
        engine.attach(playerNode)

        // Convert SIMD3<Float> to AVAudio3DPoint
        let audioPosition = AVAudio3DPoint(
            x: Double(position.x),
            y: Double(position.y),
            z: Double(position.z)
        )

        environment.attach(playerNode)
        environment.setPosition(audioPosition, of: playerNode)

        // Schedule playback
        playerNode.scheduleFile(file, at: nil) {
            // Cleanup
            engine.detach(playerNode)
            environment.detach(playerNode)
            if let idx = self.activeNodes.firstIndex(where: { $0 === playerNode }) {
                self.activeNodes.remove(at: idx)
            }
            completion?()
        }

        playerNode.play()
        activeNodes.append(playerNode)
    }

    func setListenerPosition(_ position: SIMD3<Float>) {
        environmentNode?.listenerPosition = AVAudio3DPoint(
            x: Double(position.x),
            y: Double(position.y),
            z: Double(position.z)
        )
    }

    func updateListenerFromCamera(_ cameraTransform: simd_float4x4) {
        // Camera position
        let pos = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        setListenerPosition(pos)

        // Camera orientation (forward and up vectors)
        let forward = SIMD3<Float>(
            cameraTransform.columns.2.x,
            cameraTransform.columns.2.y,
            cameraTransform.columns.2.z
        )
        let up = SIMD3<Float>(
            cameraTransform.columns.1.x,
            cameraTransform.columns.1.y,
            cameraTransform.columns.1.z
        )
        environmentNode?.listenerVectorOrientation = AVAudio3DRotation(
            forward: AVAudio3DPoint(x: Double(forward.x), y: Double(forward.y), z: Double(forward.z)),
            up: AVAudio3DPoint(x: Double(up.x), y: Double(up.y), z: Double(up.z))
        )
    }

    private func generatePlaceholderTone() -> AVAudioFile? {
        // Generate a simple 440Hz sine wave as placeholder for testing
        let sampleRate: Double = 48000
        let duration: Double = 1.0
        let frequency: Double = 440.0

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let theta = 2.0 * Double.pi * frequency / sampleRate
        for frame in 0..<Int(frameCount) {
            let sample = sin(theta * Double(frame))
            buffer.floatChannelData?.pointee[frame] = Float(sample) * 0.5
        }

        // Write to temporary file and return
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("placeholder.wav")
        try? AVAudioFile(forWriting: tempURL, settings: format.settings).write(from: buffer)

        return try? AVAudioFile(forReading: tempURL)
    }
}
