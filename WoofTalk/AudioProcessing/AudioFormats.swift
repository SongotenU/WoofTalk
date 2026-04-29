import AVFoundation

struct AudioFormats {
    static let standardSampleRate: Double = 44100.0
    static let minimumSampleRate: Double = 16000.0

    static let pcmFormat = AVAudioFormat(standardFormatWithSampleRate: standardSampleRate, channels: 1)!
    static let speechRecognitionFormat = AVAudioFormat(standardFormatWithSampleRate: 16000.0, channels: 1)!

    static func optimalBufferSize(sampleRate: Double, duration: Double) -> AVAudioFrameCount {
        AVAudioFrameCount(sampleRate * duration)
    }

    static func samples(forSeconds seconds: Double, sampleRate: Double = standardSampleRate) -> Int {
        Int(seconds * sampleRate)
    }

    static func seconds(forSamples samples: Int, sampleRate: Double = standardSampleRate) -> Double {
        Double(samples) / sampleRate
    }
}
