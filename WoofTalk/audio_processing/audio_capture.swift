//
//  audio_capture.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

import AVFoundation

class AudioCapture {
    private let engine: AVAudioEngine
    private let inputNode: AVAudioInputNode
    private var isCapturing = false
    private var bufferObservers: [(AVAudioPCMBuffer) -> Void] = []
    private let bufferManager = AudioBufferManager()
    
    init(engine: AVAudioEngine) {
        self.engine = engine
        self.inputNode = engine.inputNode
    }
    
    func start() throws {
        guard !isCapturing else { return }
        
        // Configure input format
        let inputFormat = AudioFormats.captureFormat
        
        // Install tap for real-time audio capture
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: inputFormat
        ) { [weak self] (buffer, when) in
            self?.handleBuffer(buffer)
        }
        
        try engine.start()
        isCapturing = true
    }
    
    func stop() {
        guard isCapturing else { return }
        
        inputNode.removeTap(onBus: 0)
        engine.stop()
        isCapturing = false
    }
    
    func addBufferObserver(_ observer: @escaping (AVAudioPCMBuffer) -> Void) {
        bufferObservers.append(observer)
    }
    
    func removeBufferObserver(_ observer: @escaping (AVAudioPCMBuffer) -> Void) {
        bufferObservers = bufferObservers.filter { $0 !== observer }
    }
    
    func isMicrophoneAvailable() -> Bool {
        let session = AVAudioSession.sharedInstance()
        return session.isInputAvailable
    }
    
    func getCurrentInputLatency() -> Double {
        let session = AVAudioSession.sharedInstance()
        return session.inputLatency
    }
    
    func getBufferCount() -> Int {
        return bufferObservers.count
    }
    
    private func handleBuffer(_ buffer: AVAudioPCMBuffer) {
        // Notify all observers
        bufferObservers.forEach { $0(buffer) }
        
        // Log buffer processing time
        logBufferProcessingTime(buffer)
    }
    
    private func logBufferProcessingTime(_ buffer: AVAudioPCMBuffer) {
        let currentTime = CACurrentMediaTime()
        let frameCount = buffer.frameLength
        let sampleRate = buffer.format.sampleRate
        let duration = Double(frameCount) / sampleRate
        
        // Log processing time (this would be sent to analytics in production)
        print("Processed buffer: \(frameCount) frames, \(duration * 1000)ms")
    }
}

extension AudioCapture {
    func measureLatency() -> Double {
        // This would measure actual capture to processing latency
        // For now, return estimated value based on buffer size
        return 0.005 // 5ms buffer duration
    }
    
    func getAudioLevel() -> Float {
        guard isCapturing else { return 0.0 }
        
        // Calculate RMS level from input buffer
        let buffer = AVAudioPCMBuffer(pcmFormat: AudioFormats.captureFormat, frameCapacity: 1024)!
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: AudioFormats.captureFormat) { (buffer, when) in
            var sum: Float = 0.0
            let channelData = buffer.floatChannelData?[0]
            
            for i in 0..<Int(buffer.frameLength) {
                sum += pow(channelData?[i] ?? 0.0, 2)
            }
            
            let rms = sqrt(sum / Float(buffer.frameLength))
            print("Audio level: \(rms)")
        }
        
        return 0.0 // This is a placeholder - proper implementation would require async handling
    }
}