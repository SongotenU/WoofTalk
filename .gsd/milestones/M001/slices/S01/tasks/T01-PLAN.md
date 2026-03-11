# T01: Audio Engine Foundation — Plan

**Task:** T01  
**Slice:** S01  
**Milestone:** M001  
**Date:** 2026-03-11  
**Status:** Planning  

## Description
Establish the core audio processing infrastructure with proper session configuration and audio engine setup.

## Why
The audio engine is the foundation for all real-time audio processing. Without proper configuration and initialization, we cannot achieve the low latency requirements needed for real-time translation.

## Steps

### 1. Create Audio Engine Class
```swift
// audio_processing/audio_engine.swift
import AVFoundation

class AudioEngine {
    private let engine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let outputNode: AVAudioOutputNode
    
    init() throws {
        inputNode = engine.inputNode
        outputNode = engine.outputNode
        try configureAudioSession()
        try configureAudioEngine()
    }
    
    func start() throws {
        try engine.start()
    }
    
    func stop() {
        engine.stop()
    }
}
```

### 2. Implement Audio Session Manager
```swift
// audio_processing/audio_session_manager.swift
import AVFoundation

class AudioSessionManager {
    static func configureForLowLatency() throws {
        let session = AVAudioSession.sharedInstance()
        
        try session.setCategory(.playAndRecord, options: [
            .defaultToSpeaker,
            .allowBluetooth,
            .mixWithOthers
        ])
        
        try session.setPreferredSampleRate(44100)
        try session.setPreferredIOBufferDuration(0.005) // 5ms buffer
        try session.setActive(true)
    }
    
    static func currentConfiguration() -> [String: Any] {
        let session = AVAudioSession.sharedInstance()
        return [
            "category": session.category.rawValue,
            "sampleRate": session.sampleRate,
            "bufferDuration": session.ioBufferDuration,
            "inputLatency": session.inputLatency,
            "outputLatency": session.outputLatency
        ]
    }
}
```

### 3. Define Audio Format Constants
```swift
// audio_processing/audio_formats.swift
import AVFoundation

struct AudioFormats {
    static let captureFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 1, // Mono for capture
        interleaved: false
    )!
    
    static let playbackFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 2, // Stereo for playback
        interleaved: false
    )!
    
    static let processingFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 1,
        interleaved: false
    )!
}
```

### 4. Add Error Handling
```swift
// audio_processing/audio_engine_errors.swift
import Foundation

enum AudioEngineError: LocalizedError {
    case audioSessionConfigurationFailed
    case audioEngineConfigurationFailed
    case audioSessionAlreadyActive
    case audioHardwareNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .audioSessionConfigurationFailed:
            return "Failed to configure audio session"
        case .audioEngineConfigurationFailed:
            return "Failed to configure audio engine"
        case .audioSessionAlreadyActive:
            return "Audio session is already active"
        case .audioHardwareNotAvailable:
            return "Audio hardware is not available"
        }
    }
}
```

## Must-Haves
- Audio engine class with AVAudioEngine
- Audio session manager with low-latency configuration
- Audio format constants for capture, processing, and playback
- Error handling for audio session and engine failures
- Proper initialization and cleanup

## Verification

### Unit Tests
```swift
// audio_processing/audio_engine_tests.swift
import XCTest
@testable import WoofTalk

class AudioEngineTests: XCTestCase {
    
    func testAudioEngineInitialization() throws {
        let engine = try AudioEngine()
        XCTAssertNotNil(engine)
        XCTAssertTrue(engine.engine.isRunning == false)
    }
    
    func testAudioSessionConfiguration() throws {
        try AudioSessionManager.configureForLowLatency()
        let config = AudioSessionManager.currentConfiguration()
        XCTAssertEqual(config["sampleRate"] as? Double, 44100)
        XCTAssertLessThanOrEqual(config["bufferDuration"] as? Double ?? 1.0, 0.01)
    }
    
    func testAudioFormats() throws {
        XCTAssertNotNil(AudioFormats.captureFormat)
        XCTAssertNotNil(AudioFormats.playbackFormat)
        XCTAssertNotNil(AudioFormats.processingFormat)
    }
}
```

### Integration Tests
- Verify audio engine can be started and stopped
- Check audio session configuration matches requirements
- Validate audio format constants are correctly defined

## Observability Impact
- Adds audio session state monitoring
- Implements configuration validation
- Creates error tracking surfaces
- Provides debug surfaces for audio engine state

## Inputs
- AVFoundation framework
- Core Audio capabilities
- Audio processing research from S01

## Expected Output
- Working audio engine class
- Configurable audio session manager
- Audio format utilities
- Error handling for audio failures
- Test suite with audio engine tests

## Success Criteria
- Audio engine can be instantiated without errors
- Audio session can be configured with preferred settings
- Audio format utilities return correct values
- Error handling works for invalid configurations

## Risk Mitigation
- Audio session configuration failures are caught and handled
- Engine initialization errors are properly reported
- Buffer size is optimized for low latency
- Fallback to system defaults if configuration fails

## Forward Intelligence
- Audio session configuration is critical for latency
- Buffer sizes directly impact real-time performance
- Permission status can change during app usage
- Speech recognition accuracy varies by environment

## Decision Log
- **Audio Framework:** AVFoundation chosen for native performance
- **Latency Target:** 5ms buffer size for low-latency processing
- **Error Handling:** Graceful degradation with user feedback

---

**Task T01 planned.**