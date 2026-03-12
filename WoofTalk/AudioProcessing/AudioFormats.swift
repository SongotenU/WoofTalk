import AVFoundation

struct AudioFormats {
    
    static let sampleRate: Double = 44100.0
    static let bitsPerChannel: UInt32 = 16
    static let channels: UInt32 = 1 // Mono for capture
    
    static let captureFormat: AVAudioFormat = {
        return AVAudioFormat(standardFormatWithSampleRate: sampleRate, 
                            channels: channels)!
    }()
    
    static let playbackFormat: AVAudioFormat = {
        return AVAudioFormat(standardFormatWithSampleRate: sampleRate, 
                            channels: 2)! // Stereo for playback
    }()
    
    static let pcmSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: channels,
        AVLinearPCMBitDepthKey: bitsPerChannel,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsNonInterleaved: false
    ]
    
    static func validateAudioFormat(_ format: AVAudioFormat) -> Bool {
        guard format.sampleRate == sampleRate,
              format.channelCount == channels,
              format.commonFormat == .pcmFormatInt16 else {
            return false
        }
        return true
    }
    
    static func formatDescription(_ format: AVAudioFormat) -> String {
        return "Sample Rate: \(format.sampleRate)Hz, Channels: \(format.channelCount), "
             + "Format: \(format.commonFormat.rawValue)"
    }
}