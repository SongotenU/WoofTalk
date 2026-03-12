import AVFoundation

class AudioEngine {
    
    private let engine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let outputNode: AVAudioOutputNode
    private var isRunning = false
    
    init() {
        self.inputNode = engine.inputNode
        self.outputNode = engine.outputNode
        configureAudioSession()
        setupAudioGraph()
    }
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, 
                                   options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try session.setPreferredSampleRate(44100.0)
            try session.setPreferredIOBufferDuration(0.005) // 5ms buffer for low latency
            try session.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error)")
            assertionFailure("Audio session configuration failed")
        }
    }
    
    private func setupAudioGraph() {
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let mainMixer = engine.mainMixerNode
        
        inputNode.installTap(onBus: 0, 
                             bufferSize: 1024, 
                             format: inputFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer, at: time)
        }
        
        engine.prepare()
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        // Basic audio processing - this will be enhanced in S02
        // For now, we just log buffer information for debugging
        let sampleRate = buffer.format.sampleRate
        let frameLength = buffer.frameLength
        let channelCount = buffer.format.channelCount
        
        print("Processing buffer: \(sampleRate)Hz, \(frameLength) frames, \(channelCount) channels")
    }
    
    func start() throws {
        guard !isRunning else { return }
        
        do {
            try engine.start()
            isRunning = true
            print("Audio engine started successfully")
        } catch {
            print("Failed to start audio engine: \(error)")
            throw error
        }
    }
    
    func stop() {
        guard isRunning else { return }
        
        engine.stop()
        inputNode.removeTap(onBus: 0)
        isRunning = false
        print("Audio engine stopped")
    }
    
    deinit {
        stop()
    }
}