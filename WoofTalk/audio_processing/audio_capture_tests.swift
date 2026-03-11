//
//  audio_capture_tests.swift
//  WoofTalkTests
//
//  Created by vandopha on 11/3/26.
//

import XCTest
@testable import WoofTalk

class AudioCaptureTests: XCTestCase {
    
    var audioEngine: AudioEngine!
    var audioCapture: AudioCapture!
    
    override func setUp() async throws {
        try super.setUp()
        audioEngine = try AudioEngine()
        audioCapture = AudioCapture(engine: audioEngine.getEngine())
    }
    
    override func tearDown() async throws {
        audioCapture = nil
        audioEngine = nil
        try super.tearDown()
    }
    
    func testAudioCaptureInitialization() throws {
        XCTAssertNotNil(audioCapture)
        XCTAssertFalse(audioCapture.isCapturing)
        XCTAssertNotNil(audioCapture.inputNode)
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
            XCTAssertNotNil(buffer.format)
            XCTAssertGreaterThanOrEqual(buffer.frameLength, 0)
            expectation.fulfill()
        }
        
        try audioCapture.start()
        wait(for: [expectation], timeout: 5.0)
        
        audioCapture.stop()
    }
    
    func testMicrophoneAvailability() throws {
        let available = audioCapture.isMicrophoneAvailable()
        XCTAssertNotNil(available)
    }
    
    func testInputLatency() throws {
        let latency = audioCapture.getCurrentInputLatency()
        XCTAssertGreaterThanOrEqual(latency, 0.0)
    }
    
    func testBufferCount() throws {
        XCTAssertEqual(audioCapture.getBufferCount(), 0)
        
        audioCapture.addBufferObserver { _ in }
        XCTAssertEqual(audioCapture.getBufferCount(), 1)
        
        audioCapture.addBufferObserver { _ in }
        XCTAssertEqual(audioCapture.getBufferCount(), 2)
        
        audioCapture.removeBufferObserver { _ in }
        XCTAssertEqual(audioCapture.getBufferCount(), 1)
    }
    
    func testBufferManagerIntegration() throws {
        let bufferManager = AudioBufferManager(format: AudioFormats.captureFormat)
        let buffer = bufferManager.allocateBuffer(frameCapacity: 1024)
        
        XCTAssertNotNil(buffer)
        XCTAssertEqual(buffer.frameCapacity, 1024)
        XCTAssertEqual(buffer.format.sampleRate, 44100)
        XCTAssertEqual(buffer.format.channelCount, 1)
        
        bufferManager.recycleBuffer(buffer)
        XCTAssertLessThanOrEqual(bufferManager.getCurrentPoolCount(), 10)
    }
    
    func testPermissionManager() throws {
        let status = AudioPermissionManager.checkMicrophonePermission()
        XCTAssertNotNil(status)
        
        let allPermissions = AudioPermissionManager.checkAllPermissions()
        XCTAssertNotNil(allPermissions["microphone"])
        XCTAssertNotNil(allPermissions["speech"])
    }
    
    func testPermissionExplanation() throws {
        let grantedExplanation = AudioPermissionManager.getPermissionExplanation(for: .granted)
        XCTAssertFalse(grantedExplanation.isEmpty)
        
        let deniedExplanation = AudioPermissionManager.getPermissionExplanation(for: .denied)
        XCTAssertFalse(deniedExplanation.isEmpty)
    }
}