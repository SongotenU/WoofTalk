import AVFoundation
import Accelerate

/// Analyzes audio to detect bark sounds and filter out non-bark noise (cars, people, wind)
final class BarkDetector {
    private let sampleRate: Double
    private let minimumBarkDuration: TimeInterval = 0.1
    private let maximumBarkDuration: TimeInterval = 2.0
    private let barkFrequencyRange: ClosedRange<Double> = 250...1000
    private let minBarkEnergy: Float = 0.01

    weak var delegate: BarkDetectorDelegate?

    init(sampleRate: Double = AudioFormats.standardSampleRate) {
        self.sampleRate = sampleRate
    }

    /// Returns true if the audio buffer is likely a dog bark
    func isBark(buffer: AVAudioPCMBuffer) -> Bool {
        guard let floatData = buffer.floatChannelData else { return false }
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        var isBark = false
        var maxFrequency: Double = 0
        var totalEnergy: Float = 0

        for channel in 0..<channelCount {
            let samples = floatData[channel]
            var energy: Float = 0
            vDSP_svesq(samples, 1, &energy, vDSP_Length(frameCount))
            totalEnergy += energy / Float(frameCount)

            var maxVal: Float = 0
            vDSP_maxmgv(samples, 1, &maxVal, vDSP_Length(frameCount))

            var dominantFreq: Double = 0
            for i in 1..<frameCount-1 {
                let delta = Double(samples[i] - samples[i-1])
                if abs(delta) > abs(dominantFreq) { dominantFreq = delta }
            }
            if abs(dominantFreq) > abs(maxFrequency) { maxFrequency = abs(dominantFreq) }
        }

        let avgEnergy = totalEnergy / Float(channelCount)

        guard avgEnergy > minBarkEnergy else { return false }

        let duration = Double(frameCount) / sampleRate
        guard duration >= minimumBarkDuration && duration <= maximumBarkDuration else { return false }

        let estimatedFrequency = abs(maxFrequency) * sampleRate / 4.0
        let inBarkFrequencyRange = barkFrequencyRange.contains(estimatedFrequency)

        isBark = inBarkFrequencyRange && avgEnergy > minBarkEnergy

        delegate?.barkDetector(self, didDetectBark: isBark, confidence: avgEnergy)
        return isBark
    }

    /// Process buffer and return filtered result
    func processBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) -> (shouldTranslate: Bool, buffer: AVAudioPCMBuffer) {
        let isBarkSound = isBark(buffer: buffer)
        if !isBarkSound {
            delegate?.barkDetectorDidFilterNonBark(self, buffer: buffer, at: time)
        }
        return (isBarkSound, buffer)
    }
}

protocol BarkDetectorDelegate: AnyObject {
    func barkDetector(_ detector: BarkDetector, didDetectBark isBark: Bool, confidence: Float)
    func barkDetectorDidFilterNonBark(_ detector: BarkDetector, buffer: AVAudioPCMBuffer, at time: AVAudioTime)
}
