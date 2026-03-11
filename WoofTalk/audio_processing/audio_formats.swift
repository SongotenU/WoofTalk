//
//  audio_formats.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

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
    
    static let speechRecognitionFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16000, // Speech recognition often works better at 16kHz
        channels: 1,
        interleaved: false
    )!
    
    static func validateFormat(_ format: AVAudioFormat) -> Bool {
        guard let channels = format.channelCount else { return false }
        return channels > 0 && channels <= 2 && format.sampleRate >= 8000 && format.sampleRate <= 48000
    }
    
    static func getFormatDescription(_ format: AVAudioFormat) -> String {
        return "Sample Rate: \(format.sampleRate), Channels: \(format.channelCount ?? 0), Format: \(format.commonFormat.rawValue)"
    }
}