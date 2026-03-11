# T04: Audio Playback Module — Plan

**Task:** T04  
**Slice:** S01  
**Milestone:** M001  
**Date:** 2026-03-11  
**Status:** Planning  

## Description
Implement audio playback for translation output with proper routing, latency optimization, and audio synthesis capabilities.

## Why
Audio playback is essential for delivering translated content back to users. Without proper playback implementation, we cannot provide the speech-to-speech translation experience.

## Steps

### 1. Create Audio Playback Class
```swift
// audio_processing/audio_playback.swift
import AVFoundation

class AudioPlayback {
    private let engine: AVAudioEngine
    private let outputNode: AVAudioOutputNode
    private var isPlaying = false
    private var currentPlayer: AVAudioPlayerNode?
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private let bufferManager = AudioBufferManager()
    
    init(engine: AVAudioEngine) {
        self.engine = engine
        self.outputNode = engine.outputNode
        self.currentPlayer = AVAudioPlayerNode()
        
        // Attach player to engine
        engine.attach(currentPlayer!)
        
        // Connect player to output
        engine.connect(
            currentPlayer!,
            to: outputNode,
            format: AudioFormats.playbackFormat
        )
    }
    
    func start() throws {
        guard !isPlaying else { return }
        
        try engine.start()
        isPlaying = true
    }
    
    func stop() {
        guard isPlaying else { return }
        
        currentPlayer?.stop()
        engine.stop()
        isPlaying = false
    }
    
    func playBuffer(_ buffer: AVAudioPCMBuffer) throws {
        guard isPlaying else { throw AudioPlaybackError.notPlaying }
        
        // Schedule buffer for playback
        currentPlayer?.scheduleBuffer(buffer) {
            // Buffer completed callback
            self.handleBufferCompleted(buffer)
        }
        
        currentPlayer?.play()
    }
    
    private func handleBufferCompleted(_ buffer: AVAudioPCMBuffer) {
        // Recycle buffer
        bufferManager.recycleBuffer(buffer)
        
        // Log completion
        print("Buffer playback completed: \(buffer.frameLength) frames")
    }
}
```

### 2. Implement Audio Synthesis
```swift
// audio_processing/audio_synthesis.swift
import AVFoundation

class AudioSynthesis {
    static func synthesizeSpeech(from text: String, voice: AVSpeechSynthesisVoice? = nil) -> AVAudioPCMBuffer? {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice ?? AVSpeechSynthesisVoice(language: "en-US")
        
        // Create audio format
        let format = AudioFormats.playbackFormat
        
        // Create buffer for synthesis
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(utterance.speechString.count * 100)
        )
        
        // Perform synthesis
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.write(utterance) { [weak buffer] (buffer1, _) in
            buffer = buffer1
        }
        
        return buffer
    }
    
    static func synthesizeTone(frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        let format = AudioFormats.playbackFormat
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else { return nil }
        
        buffer.frameLength = frameCount
        
        // Generate sine wave
        let channelData = buffer.floatChannelData?[0]
        let phaseIncrement = 2.0 * Double.pi * frequency / sampleRate
        
        for i in 0..<Int(frameCount) {
            let sample = sin(phaseIncrement * Double(i))
            channelData?[i] = Float(sample)
        }
        
        return buffer
    }
    
    static func synthesizeDogSound(type: DogSoundType, intensity: Double) -> AVAudioPCMBuffer? {
        switch type {
        case .bark:
            return synthesizeBark(intensity: intensity)
        case .whine:
            return synthesizeWhine(intensity: intensity)
        case .growl:
            return synthesizeGrowl(intensity: intensity)
        }
    }
    
    private static func synthesizeBark(intensity: Double) -> AVAudioPCMBuffer? {
        // Generate a realistic bark sound
        let format = AudioFormats.playbackFormat
        let duration: Double = 0.5 + (intensity * 0.5) // 0.5 to 1.0 seconds
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else { return nil }
        
        buffer.frameLength = frameCount
        
        let channelData = buffer.floatChannelData?[0]
        
        // Generate complex bark waveform
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let frequency = 500 + (intensity * 1000) // 500Hz to 1500Hz
            let amplitude = Float(0.5 + (intensity * 0.5))
            
            let sample = amplitude * sin(2.0 * Double.pi * frequency * t) * 
                        (1.0 + 0.5 * sin(2.0 * Double.pi * (frequency * 2.0) * t))
            
            channelData?[i] = sample
        }
        
        return buffer
    }
    
    private static func synthesizeWhine(intensity: Double) -> AVAudioPCMBuffer? {
        // Generate a high-pitched whine sound
        let format = AudioFormats.playbackFormat
        let duration: Double = 1.0 + (intensity * 1.0) // 1.0 to 2.0 seconds
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else { return nil }
        
        buffer.frameLength = frameCount
        
        let channelData = buffer.floatChannelData?[0]
        
        // Generate whine waveform with frequency modulation
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let baseFrequency = 1000 + (intensity * 2000) // 1000Hz to 3000Hz
            let modulationFrequency = 5.0 + (intensity * 10.0) // 5Hz to 15Hz
            let modulationDepth = 0.2 + (intensity * 0.3) // 0.2 to 0.5
            
            let modulatedFrequency = baseFrequency * (1.0 + modulationDepth * sin(2.0 * Double.pi * modulationFrequency * t))
            let sample = sin(2.0 * Double.pi * modulatedFrequency * t)
            
            channelData?[i] = Float(sample)
        }
        
        return buffer
    }
    
    private static func synthesizeGrowl(intensity: Double) -> AVAudioPCMBuffer? {
        // Generate a low, rumbling growl sound
        let format = AudioFormats.playbackFormat
        let duration: Double = 2.0 + (intensity * 2.0) // 2.0 to 4.0 seconds
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCount
        ) else { return nil }
        
        buffer.frameLength = frameCount
        
        let channelData = buffer.floatChannelData?[0]
        
        // Generate growl with multiple frequency components
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let baseFrequency = 100 + (intensity * 200) // 100Hz to 300Hz
            let harmonic1 = baseFrequency * 2.0
            let harmonic2 = baseFrequency * 3.0
            
            let sample = (0.5 * sin(2.0 * Double.pi * baseFrequency * t)) +
                        (0.3 * sin(2.0 * Double.pi * harmonic1 * t)) +
                        (0.2 * sin(2.0 * Double.pi * harmonic2 * t))
            
            channelData?[i] = Float(sample)
        }
        
        return buffer
    }
}

enum DogSoundType {
    case bark
    case whine
    case growl
}
```

### 3. Add Volume and Routing Control
```swift
// audio_processing/audio_playback_routing.swift
import AVFoundation

extension AudioPlayback {
    func setVolume(_ volume: Float) {
        currentPlayer?.volume = volume
    }
    
    func getVolume() -> Float {
        return currentPlayer?.volume ?? 1.0
    }
    
    func setOutput(to route: AudioOutputRoute) throws {
        let session = AVAudioSession.sharedInstance()
        
        switch route {
        case .speaker:
            try session.setCategory(.playAndRecord, options: [
                .defaultToSpeaker,
                .allowBluetooth,
                .mixWithOthers
            ])
        case .receiver:
            try session.setCategory(.playAndRecord, options: [
                .defaultToSpeaker,
                .allowBluetooth,
                .mixWithOthers
            ])
        case .bluetooth:
            try session.setCategory(.playAndRecord, options: [
                .allowBluetooth,
                .mixWithOthers
            ])
        case .headphones:
            try session.setCategory(.playAndRecord, options: [
                .mixWithOthers
            ])
        }
        
        try session.setActive(true)
    }
    
    func getCurrentRoute() -> AudioOutputRoute {
        let session = AVAudioSession.sharedInstance()
        
        if session.currentRoute.outputs.contains(where: { $0.portType == .builtInSpeaker }) {
            return .speaker
        } else if session.currentRoute.outputs.contains(where: { $0.portType == .builtInReceiver }) {
            return .receiver
        } else if session.currentRoute.outputs.contains(where: { $0.portType == .bluetoothA2DP || $0.portType == .bluetoothHFP }) {
            return .bluetooth
        } else if session.currentRoute.outputs.contains(where: { $0.portType == .headphones }) {
            return .headphones
        }
        
        return .speaker // Default
    }
}

enum AudioOutputRoute {
    case speaker
    case receiver
    case bluetooth
    case headphones
}
```

### 4. Implement Latency Optimization
```swift
// audio_processing/audio_playback_latency.swift
import AVFoundation

extension AudioPlayback {
    func optimizeForLowLatency() throws {
        let session = AVAudioSession.sharedInstance()
        
        // Set preferred IO buffer duration for low latency
        try session.setPreferredIOBufferDuration(0.005) // 5ms
        
        // Set preferred sample rate
        try session.setPreferredSampleRate(44100)
        
        // Activate session with new settings
        try session.setActive(true)
    }
    
    func measurePlaybackLatency() -> Double {
        // Measure actual playback latency
        let session = AVAudioSession.sharedInstance()
        let outputLatency = session.outputLatency
        let bufferDuration = session.ioBufferDuration
        
        return outputLatency + bufferDuration
    }
    
    func getPlaybackMetrics() -> [String: Any] {
        let session = AVAudioSession.sharedInstance()
        return [
            "outputLatency": session.outputLatency,
            "inputLatency": session.inputLatency,
            "bufferDuration": session.ioBufferDuration,
            "sampleRate": session.sampleRate,
            "isPlaying": isPlaying
        ]
    }
}
```

## Must-Haves
- Audio playback class with AVAudioPlayerNode
- Audio synthesis for speech and dog sounds
- Volume and routing control
- Latency optimization methods
- Proper buffer management and recycling

## Verification

### Unit Tests
```swift
// audio_processing/audio_playback_tests.swift
import XCTest
@testable import WoofTalk

class AudioPlaybackTests: XCTestCase {
    
    var audioEngine: AudioEngine!
    var audioPlayback: AudioPlayback!
    
    override func setUp() async throws {
        audioEngine = try AudioEngine()
        audioPlayback = AudioPlayback(engine: audioEngine.engine)
    }
    
    func testAudioPlaybackInitialization() throws {
        XCTAssertNotNil(audioPlayback)
        XCTAssertNotNil(audioPlayback.currentPlayer)
    }
    
    func testStartStopPlayback() throws {
        try audioPlayback.start()
        XCTAssertTrue(audioPlayback.isPlaying)
        
        audioPlayback.stop()
        XCTAssertFalse(audioPlayback.isPlaying)
    }
    
    func testPlayBuffer() throws {
        // Create test buffer
        let format = AudioFormats.playbackFormat
        let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: 1024
        )!
        buffer.frameLength = 1024
        
        // Fill buffer with test data
        let channelData = buffer.floatChannelData?[0]
        for i in 0..<1024 {
            channelData?[i] = Float(sin(2.0 * Double.pi * 440.0 * Double(i) / 44100.0))
        }
        
        try audioPlayback.playBuffer(buffer)
        // Verify buffer was scheduled (would need more sophisticated testing)
    }
    
    func testAudioSynthesis() throws {
        let speechBuffer = AudioSynthesis.synthesizeSpeech(from: "Test")
        XCTAssertNotNil(speechBuffer)
        
        let toneBuffer = AudioSynthesis.synthesizeTone(frequency: 440, duration: 1.0)
        XCTAssertNotNil(toneBuffer)
        
        let barkBuffer = AudioSynthesis.synthesizeDogSound(type: .bark, intensity: 0.8)
        XCTAssertNotNil(barkBuffer)
    }
    
    func testVolumeControl() throws {
        try audioPlayback.start()
        
        audioPlayback.setVolume(0.5)
        XCTAssertEqual(audioPlayback.getVolume(), 0.5)
        
        audioPlayback.setVolume(1.0)
        XCTAssertEqual(audioPlayback.getVolume(), 1.0)
        
        audioPlayback.stop()
    }
    
    func testLatencyOptimization() throws {
        try audioPlayback.optimizeForLowLatency()
        
        let metrics = audioPlayback.getPlaybackMetrics()
        XCTAssertLessThanOrEqual(metrics["bufferDuration"] as? Double ?? 1.0, 0.01)
        XCTAssertLessThanOrEqual(metrics["outputLatency"] as? Double ?? 1.0, 0.05)
    }
}
```

### Integration Tests
- Verify audio playback can play synthesized speech
- Check dog sound synthesis produces realistic sounds
- Validate routing changes work correctly
- Test latency optimization reduces playback delay

## Observability Impact
- Adds playback metrics monitoring
- Implements routing state tracking
- Creates buffer completion tracking
- Provides debug surfaces for playback state

## Inputs
- AVFoundation framework
- Audio engine from T01
- Audio formats from T01
- Buffer management from T02

## Expected Output
- Working audio playback class
- Audio synthesis for speech and dog sounds
- Volume and routing control
- Latency optimization methods
- Test suite with playback tests

## Success Criteria
- Audio playback can play synthesized speech and sounds
- Volume and routing controls work correctly
- Latency is optimized for real-time translation
- Buffer management prevents memory issues

## Risk Mitigation
- Playback failures are caught and handled
- Buffer overflow is prevented with pool management
- Routing changes are validated before application
- Fallback to system defaults if configuration fails

## Forward Intelligence
- Audio session configuration is critical for latency
- Buffer sizes directly impact real-time performance
- Permission status can change during app usage
- Speech recognition accuracy varies by environment

## Decision Log
- **Audio Framework:** AVAudioPlayerNode for flexible playback
- **Synthesis Method:** AVSpeechSynthesizer for speech, custom for dog sounds
- **Latency Target:** 5ms buffer size for low-latency processing
- **Error Handling:** Graceful degradation with user feedback

---

**Task T04 planned.**