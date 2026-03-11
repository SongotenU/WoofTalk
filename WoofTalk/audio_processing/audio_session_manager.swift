//
//  audio_session_manager.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

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
            "outputLatency": session.outputLatency,
            "inputChannels": session.inputNumberOfChannels,
            "outputChannels": session.outputNumberOfChannels
        ]
    }
    
    static func resetAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setActive(false)
        try session.setCategory(.ambient)
    }
}