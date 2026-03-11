//
//  audio_engine_tests.swift
//  WoofTalkTests
//
//  Created by vandopha on 11/3/26.
//

import XCTest
@testable import WoofTalk

class AudioEngineTests: XCTestCase {
    
    var audioEngine: AudioEngine!
    
    override func setUp() async throws {
        try super.setUp()
        audioEngine = try AudioEngine()
    }
    
    override func tearDown() async throws {
        audioEngine = nil
        try super.tearDown()
    }
    
    func testAudioEngineInitialization() throws {
        XCTAssertNotNil(audioEngine)
        XCTAssertNotNil(audioEngine.getEngine())
    }
    
    func testAudioSessionConfiguration() throws {
        try AudioSessionManager.configureForLowLatency()
        let config = AudioSessionManager.currentConfiguration()
        
        XCTAssertEqual(config["sampleRate"] as? Double, 44100, accuracy: 1.0)
        XCTAssertLessThanOrEqual(config["bufferDuration"] as? Double ?? 1.0, 0.01)
        XCTAssertEqual(config["category"] as? String, AVAudioSession.Category.playAndRecord.rawValue)
    }
    
    func testAudioFormats() throws {
        XCTAssertNotNil(AudioFormats.captureFormat)
        XCTAssertNotNil(AudioFormats.playbackFormat)
        XCTAssertNotNil(AudioFormats.processingFormat)
        
        XCTAssertTrue(AudioFormats.validateFormat(AudioFormats.captureFormat))
        XCTAssertTrue(AudioFormats.validateFormat(AudioFormats.playbackFormat))
        XCTAssertTrue(AudioFormats.validateFormat(AudioFormats.processingFormat))
    }
    
    func testAudioFormatDescriptions() throws {
        let description = AudioFormats.getFormatDescription(AudioFormats.captureFormat)
        XCTAssertFalse(description.isEmpty)
        XCTAssertTrue(description.contains("Sample Rate:"))
        XCTAssertTrue(description.contains("Channels:"))
    }
    
    func testAudioEngineStartStop() throws {
        try audioEngine.start()
        XCTAssertTrue(audioEngine.getEngine().isRunning)
        
        audioEngine.stop()
        XCTAssertFalse(audioEngine.getEngine().isRunning)
    }
    
    func testAudioSessionReset() throws {
        try AudioSessionManager.resetAudioSession()
        let config = AudioSessionManager.currentConfiguration()
        XCTAssertEqual(config["category"] as? String, AVAudioSession.Category.ambient.rawValue)
    }
    
    func testSpeechRecognitionFormat() throws {
        XCTAssertNotNil(AudioFormats.speechRecognitionFormat)
        XCTAssertEqual(AudioFormats.speechRecognitionFormat.sampleRate, 16000)
        XCTAssertEqual(AudioFormats.speechRecognitionFormat.channelCount, 1)
    }
}