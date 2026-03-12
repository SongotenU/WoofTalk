// MARK: - AudioFormats

import AVFoundation

/// Audio format constants and utilities for optimal audio processing
struct AudioFormats {
    
    // MARK: - Core Format Constants
    
    /// Preferred sample rate for audio processing (44.1 kHz)
    static let preferredSampleRate: Double = 44100.0
    
    /// Standard sample rate for audio processing (44.1 kHz)
    static let standardSampleRate: Double = 44100.0
    
    /// Minimum sample rate for basic audio processing (16 kHz)
    static let minimumSampleRate: Double = 16000.0
    
    /// Preferred buffer duration for low-latency processing (5 ms)
    static let preferredBufferDuration: Double = 0.005
    
    /// Standard buffer duration for balanced processing (10 ms)
    static let standardBufferDuration: Double = 0.01
    
    /// Maximum buffer duration for background processing (50 ms)
    static let maximumBufferDuration: Double = 0.05
    
    // MARK: - Audio Format Definitions
    
    /// Standard PCM audio format for processing
    static let pcmFormat: AVAudioFormat = {
        return AVAudioFormat(standardFormatWithSampleRate: standardSampleRate, channels: 1)!
    }()
    
    /// Stereo audio format for playback
    static let stereoFormat: AVAudioFormat = {
        return AVAudioFormat(standardFormatWithSampleRate: standardSampleRate, channels: 2)!
    }()
    
    /// Speech recognition optimized format
    static let speechRecognitionFormat: AVAudioFormat = {
        return AVAudioFormat(standardFormatWithSampleRate: 16000.0, channels: 1)!
    }()
    
    // MARK: - Quality Constants
    
    /// Audio quality levels for processing
    enum Quality {
        case low    // 8 kHz, mono
        case medium // 16 kHz, mono
        case high   // 44.1 kHz, mono
        case stereo // 44.1 kHz, stereo
    }
    
    /// Audio bit depth constants
    enum BitDepth {
        case pcm16  // 16-bit PCM
        case pcm24  // 24-bit PCM
        case pcm32  // 32-bit PCM
    }
    
    // MARK: - Format Utilities
    
    /// Get audio format for specific quality level
    static func format(for quality: Quality) -> AVAudioFormat {
        switch quality {
        case .low:
            return AVAudioFormat(standardFormatWithSampleRate: 8000.0, channels: 1)!
        case .medium:
            return AVAudioFormat(standardFormatWithSampleRate: 16000.0, channels: 1)!
        case .high:
            return AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
        case .stereo:
            return AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!
        }
    }
    
    /// Get optimal buffer size for sample rate and duration
    static func optimalBufferSize(sampleRate: Double, duration: Double) -> AVAudioFrameCount {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        return frameCount
    }
    
    /// Convert seconds to sample count
    static func samples(forSeconds seconds: Double, sampleRate: Double = standardSampleRate) -> Int {
        return Int(seconds * sampleRate)
    }
    
    /// Convert sample count to seconds
    static func seconds(forSamples samples: Int, sampleRate: Double = standardSampleRate) -> Double {
        return Double(samples) / sampleRate
    }
    
    // MARK: - Validation
    
    /// Validate audio format for processing
    static func validateFormat(_ format: AVAudioFormat) -> Bool {
        guard let sampleRate = format.sampleRate,
              sampleRate >= minimumSampleRate else {
            return false
        }
        
        guard format.channelCount >= 1 else {
            return false
        }
        
        return true
    }
    
    /// Validate sample rate for speech recognition
    static func validateSampleRateForSpeechRecognition(_ sampleRate: Double) -> Bool {
        return sampleRate >= 16000.0 && sampleRate <= 48000.0
    }
    
    // MARK: - Audio Metadata
    
    /// Get human-readable format description
    static func formatDescription(for format: AVAudioFormat) -> String {
        let sampleRate = format.sampleRate
        let channels = format.channelCount
        return String(format: "%.0f kHz, %d channels", sampleRate / 1000.0, channels)
    }
    
    /// Get latency information for format
    static func latencyInfo(for format: AVAudioFormat) -> (capture: Double, processing: Double, playback: Double) {
        let captureLatency = 0.005 // 5 ms capture latency
        let processingLatency = 0.002 // 2 ms processing latency
        let playbackLatency = 0.003 // 3 ms playback latency
        return (captureLatency, processingLatency, playbackLatency)
    }
    
    // MARK: - Audio Conversion
    
    /// Convert PCM buffer to normalized float buffer
    static func normalizeBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = buffer.format,
              let floatBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else {
            return nil
        }
        
        // Normalize to -1.0 to 1.0 range
        let samples = Int(buffer.frameLength)
        let channels = Int(format.channelCount)
        
        for channel in 0..<channels {
            guard let srcChannel = buffer.floatChannelData?[channel],
                  let dstChannel = floatBuffer.floatChannelData?[channel] else {
                continue
            }
            
            for sample in 0..<samples {
                let normalized = srcChannel[sample] / 32768.0
                dstChannel[sample] = normalized
            }
        }
        
        floatBuffer.frameLength = buffer.frameLength
        return floatBuffer
    }
    
    /// Convert float buffer to PCM buffer
    static func denormalizeBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = buffer.format,
              let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else {
            return nil
        }
        
        // Denormalize from -1.0 to 1.0 range
        let samples = Int(buffer.frameLength)
        let channels = Int(format.channelCount)
        
        for channel in 0..<channels {
            guard let srcChannel = buffer.floatChannelData?[channel],
                  let dstChannel = pcmBuffer.floatChannelData?[channel] else {
                continue
            }
            
            for sample in 0..<samples {
                let denormalized = srcChannel[sample] * 32768.0
                dstChannel[sample] = denormalized
            }
        }
        
        pcmBuffer.frameLength = buffer.frameLength
        return pcmBuffer
    }
}

// MARK: - AudioFormat Extensions

extension AVAudioFormat {
    /// Get format description for debugging
    var formatDescription: String {
        let sampleRate = sampleRate ?? 0
        let channels = channelCount
        return String(format: "%.0f kHz, %d channels", sampleRate / 1000.0, channels)
    }
    
    /// Check if format is suitable for speech recognition
    var isSuitableForSpeechRecognition: Bool {
        return sampleRate ?? 0 >= 16000.0 && channelCount >= 1
    }
    
    /// Check if format is suitable for low-latency processing
    var isSuitableForLowLatency: Bool {
        return sampleRate ?? 0 >= 8000.0 && channelCount >= 1
    }
}