//
//  audio_engine.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

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
    
    func getEngine() -> AVAudioEngine {
        return engine
    }
}

extension AudioEngine {
    private func configureAudioSession() throws {
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
    
    private func configureAudioEngine() throws {
        // Basic configuration - more specific setup will be done in capture/playback modules
        engine.connect(engine.inputNode, to: engine.mainMixerNode, format: AudioFormats.captureFormat)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: AudioFormats.playbackFormat)
    }
}

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