# T02: Audio Capture Module — Plan

**Task:** T02  
**Slice:** S01  
**Milestone:** M001  
**Date:** 2026-03-11  
**Status:** Planning  

## Description
Implement real-time audio capture from microphone with proper buffer management and permission handling.

## Why
Audio capture is the first step in the translation pipeline. Without reliable microphone input and proper buffer management, we cannot process any audio for translation.

## Steps

### 1. Create Audio Capture Class
```swift
// audio_processing/audio_capture.swift
import AVFoundation

class AudioCapture {
    private let engine: AVAudioEngine
    private let inputNode: AVAudioInputNode
    private var isCapturing = false
    private var bufferObservers: [(AVAudioPCMBuffer) -> Void] = []
    
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
    
    private func handleBuffer(_ buffer: AVAudioPCMBuffer) {
        // Notify all observers
        bufferObservers.forEach { $0(buffer) }
        
        // Log buffer processing time
        logBufferProcessingTime(buffer)
    }
}
```

### 2. Implement Audio Buffer Manager
```swift
// audio_processing/audio_buffer_manager.swift
import AVFoundation

class AudioBufferManager {
    private let queue = DispatchQueue(label: "audio.buffer.queue")
    private var bufferPool: [AVAudioPCMBuffer] = []
    private let maxPoolSize = 10
    
    func allocateBuffer(format: AVAudioFormat, frameCapacity: AVAudioFrameCount) -> AVAudioPCMBuffer {
        queue.sync {
            if let buffer = bufferPool.popLast() {
                buffer.frameLength = 0
                return buffer
            }
        }
        
        return AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: frameCapacity
        )!
    }
    
    func recycleBuffer(_ buffer: AVAudioPCMBuffer) {
        queue.sync {
            if bufferPool.count < maxPoolSize {
                bufferPool.append(buffer)
            }
        }
    }
    
    func currentPoolCount() -> Int {
        queue.sync { bufferPool.count }
    }
}
```

### 3. Add Permission Handling
```swift
// audio_processing/audio_permissions.swift
import AVFoundation
import Speech

enum AudioPermissionStatus: String {
    case granted = "granted"
    case denied = "denied"
    case notDetermined = "notDetermined"
    case restricted = "restricted"
}

class AudioPermissionManager {
    static func checkMicrophonePermission() -> AudioPermissionStatus {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    static func requestMicrophonePermission(completion: @escaping (AudioPermissionStatus) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted ? .granted : .denied)
            }
        }
    }
    
    static func checkSpeechPermission() -> AudioPermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    static func requestSpeechPermission(completion: @escaping (AudioPermissionStatus) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status.toPermissionStatus())
            }
        }
    }
}

extension SFSpeechRecognizerAuthorizationStatus {
    func toPermissionStatus() -> AudioPermissionStatus {
        switch self {
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
}
```

### 4. Implement Buffer Callback with Timing
```swift
// audio_processing/audio_capture_timing.swift
import AVFoundation

extension AudioCapture {
    private func logBufferProcessingTime(_ buffer: AVAudioPCMBuffer) {
        let currentTime = CACurrentMediaTime()
        let frameCount = buffer.frameLength
        let sampleRate = buffer.format.sampleRate
        let duration = Double(frameCount) / sampleRate
        
        // Log processing time (this would be sent to analytics in production)
        print("Processed buffer: \(frameCount) frames, \(duration * 1000)ms")
    }
    
    func measureLatency() -> Double {
        // This would measure actual capture to processing latency
        // For now, return estimated value based on buffer size
        return 0.005 // 5ms buffer duration
    }
}
```

## Must-Haves
- Audio capture class with microphone input
- Audio buffer manager for real-time processing
- Permission handling for microphone and speech recognition
- Buffer callback with timing measurements
- Proper start/stop functionality

## Verification

### Unit Tests
```swift
// audio_processing/audio_capture_tests.swift
import XCTest
@testable import WoofTalk

class AudioCaptureTests: XCTestCase {
    
    var audioEngine: AudioEngine!
    var audioCapture: AudioCapture!
    
    override func setUp() async throws {
        audioEngine = try AudioEngine()
        audioCapture = AudioCapture(engine: audioEngine.engine)
    }
    
    func testAudioCaptureInitialization() throws {
        XCTAssertNotNil(audioCapture)
        XCTAssertFalse(audioCapture.isCapturing)
    }
    
    func testStartStopCapture() throws {
        try audioCapture.start()
        XCTAssertTrue(audioCapture.isCapturing)
        
        audioCapture.stop()
        XCTAssertFalse(audioCapture.isCapturing)
    }
    
    func testBufferObserver() throws {
        let expectation = XCTestExpectation(description: "Buffer received")
        
        audioCapture.addBufferObserver { buffer in
            XCTAssertNotNil(buffer)
            expectation.fulfill()
        }
        
        try audioCapture.start()
        wait(for: [expectation], timeout: 5.0)
        
        audioCapture.stop()
    }
    
    func testMicrophonePermission() throws {
        let status = AudioPermissionManager.checkMicrophonePermission()
        XCTAssert(status == .granted || status == .notDetermined || status == .denied)
    }
}
```

### Integration Tests
- Verify audio capture can be started and stopped
- Check buffer processing time is within acceptable limits
- Validate permission handling works correctly
- Test buffer manager recycles buffers properly

## Observability Impact
- Adds buffer processing time monitoring
- Implements permission status tracking
- Creates buffer pool size monitoring
- Provides debug surfaces for capture state

## Inputs
- AVFoundation framework
- Audio engine from T01
- Permission handling requirements
- Buffer management research

## Expected Output
- Working audio capture class
- Buffer manager with pool recycling
- Permission handling utilities
- Buffer callback with timing
- Test suite with capture tests

## Success Criteria
- Audio capture can be started and stopped
- Microphone permission requests work correctly
- Audio buffers are produced at expected intervals
- Buffer processing time is measured and logged

## Risk Mitigation
- Permission denial is handled gracefully
- Buffer overflow is prevented with pool management
- Engine start failures are caught and reported
- Fallback to system defaults if configuration fails

## Forward Intelligence
- Audio session configuration is critical for latency
- Buffer sizes directly impact real-time performance
- Permission status can change during app usage
- Speech recognition accuracy varies by environment

## Decision Log
- **Buffer Size:** 1024 frames for balance between latency and CPU usage
- **Pool Size:** 10 buffers for memory efficiency
- **Permission Handling:** Clear user communication and fallback paths

---

**Task T02 planned.**