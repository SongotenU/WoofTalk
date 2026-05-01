import AVFoundation
import Accelerate

/// Detects dog emotions from audio input by analyzing pitch, frequency spectrum, and duration patterns
final class DogEmotionDetector {

    struct AudioFeatures {
        let pitch: Double
        let frequencySpectrum: [Double]
        let duration: Double
        let amplitude: Double
        let frequency: Double
    }

    struct EmotionResult {
        let emotion: DogEmotion
        let confidence: Double
        let features: AudioFeatures
    }

    func detectEmotion(from buffer: AVAudioPCMBuffer) -> EmotionResult {
        let features = extractFeatures(from: buffer)
        let (emotion, confidence) = classifyEmotion(features: features)
        return EmotionResult(emotion: emotion, confidence: confidence, features: features)
    }

    private func extractFeatures(from buffer: AVAudioPCMBuffer) -> AudioFeatures {
        guard let channelData = buffer.floatChannelData else {
            return AudioFeatures(pitch: 0, frequencySpectrum: [], duration: 0, amplitude: 0, frequency: 0)
        }

        let frames = Int(buffer.frameLength)
        let data = channelData[0]
        let sampleRate = buffer.format.sampleRate

        // Calculate duration
        let duration = Double(frames) / sampleRate

        // Calculate amplitude (RMS)
        var rms: Float = 0
        vDSP_measqv(data, 1, &rms, vDSP_Length(frames))
        let amplitude = sqrt(rms)

        // Estimate pitch using zero-crossing rate
        var zeroCrossings = 0
        for i in 1..<frames {
            if (data[i] >= 0 && data[i-1] < 0) || (data[i] < 0 && data[i-1] >= 0) {
                zeroCrossings += 1
            }
        }
        let pitch = Double(zeroCrossings) * sampleRate / (2.0 * Double(frames))

        // Simple frequency estimation (dominant frequency via peak detection)
        let frequency = estimateDominantFrequency(data, frameCount: frames, sampleRate: sampleRate)

        // Frequency spectrum (simplified - using band energy)
        let spectrum = calculateSpectrumBands(data, frameCount: frames, sampleRate: sampleRate)

        return AudioFeatures(
            pitch: pitch,
            frequencySpectrum: spectrum,
            duration: duration,
            amplitude: Double(amplitude),
            frequency: frequency
        )
    }

    private func estimateDominantFrequency(_ data: UnsafePointer<Float>, frameCount: Int, sampleRate: Double) -> Double {
        // Simple autocorrelation-based pitch estimation
        var correlation: [Float] = Array(repeating: 0, count: min(1000, frameCount))
        let maxLag = min(1000, frameCount / 2)

        for lag in 1..<maxLag {
            var sum: Float = 0
            for i in 0..<frameCount - lag {
                sum += data[i] * data[i + lag]
            }
            correlation[lag] = sum
        }

        // Find peak in correlation
        var maxCorr: Float = 0
        var maxLagIndex = 1
        for lag in 1..<maxLag {
            if correlation[lag] > maxCorr {
                maxCorr = correlation[lag]
                maxLagIndex = lag
            }
        }

        guard maxLagIndex > 0 else { return 0 }
        return sampleRate / Double(maxLagIndex)
    }

    private func calculateSpectrumBands(_ data: UnsafePointer<Float>, frameCount: Int, sampleRate: Double) -> [Double] {
        // Divide into 4 frequency bands: low, mid-low, mid-high, high
        let bands = 4
        var bandEnergy = [Double](repeating: 0, count: bands)

        // Simple energy calculation per band (based on frequency ranges)
        let nyquist = sampleRate / 2
        let bandWidth = nyquist / Double(bands)

        for band in 0..<bands {
            let lowerFreq = Double(band) * bandWidth
            let upperFreq = Double(band + 1) * bandWidth
            // Simplified: just use amplitude in corresponding sample range
            let startIdx = Int(Double(frameCount) * lowerFreq / nyquist)
            let endIdx = min(Int(Double(frameCount) * upperFreq / nyquist), frameCount)
            guard startIdx < endIdx else { continue }
            var energy: Float = 0
            vDSP_measqv(data.advanced(by: startIdx), 1, &energy, vDSP_Length(endIdx - startIdx))
            bandEnergy[band] = Double(energy)
        }

        return bandEnergy
    }

    private func classifyEmotion(features: AudioFeatures) -> (DogEmotion, Double) {
        let pitch = features.pitch
        let duration = features.duration
        let amplitude = features.amplitude

        // Classification rules based on audio features
        // Happy: medium pitch, short duration, moderate amplitude
        if pitch > 300 && pitch < 600 && duration < 1.5 && amplitude > 0.3 {
            return (.happy, 0.85)
        }

        // Playful: high pitch, short bursts, high amplitude
        if pitch > 500 && duration < 1.0 && amplitude > 0.5 {
            return (.playful, 0.80)
        }

        // Alert: medium-high pitch, medium duration, high amplitude
        if pitch > 400 && duration > 1.0 && duration < 2.5 && amplitude > 0.6 {
            return (.excited, 0.82)
        }

        // Distressed: high pitch, long duration, variable amplitude
        if pitch > 600 && duration > 2.0 {
            return (.scared, 0.75)
        }

        // Aggressive: low pitch, long duration, high amplitude
        if pitch < 300 && duration > 2.0 && amplitude > 0.7 {
            return (.aggressive, 0.78)
        }

        // Tired: low pitch, long duration, low amplitude
        if pitch < 350 && amplitude < 0.3 {
            return (.tired, 0.70)
        }

        // Territorial: medium pitch, medium-long duration, increasing amplitude
        if pitch > 250 && pitch < 450 && duration > 1.5 && amplitude > 0.4 {
            return (.territorial, 0.72)
        }

        // Default: neutral
        return (.neutral, 0.60)
    }
}
