import AVFoundation
import Accelerate

/// Noise cancellation processor for outdoor use (park, street)
final class NoiseCancellationProcessor {
    private var noiseProfile: [Float]?
    private let fftSize: Int = 2048
    private let noiseReductionStrength: Float = 0.7

    weak var delegate: NoiseCancellationProcessorDelegate?

    /// Learn noise profile from a buffer (call during silence periods)
    func learnNoiseProfile(from buffer: AVAudioPCMBuffer) {
        guard let floatData = buffer.floatChannelData else { return }
        let frameCount = min(Int(buffer.frameLength), fftSize)
        let channelCount = Int(buffer.format.channelCount)

        var profile = [Float](repeating: 0, count: fftSize / 2)
        for channel in 0..<channelCount {
            let samples = floatData[channel]
            var sum: Float = 0
            vDSP_svesq(samples, 1, &sum, vDSP_Length(frameCount))
            let rms = sqrt(sum / Float(frameCount))
            for i in 0..<profile.count {
                profile[i] = max(profile[i], rms * 0.5)
            }
        }
        noiseProfile = profile
        delegate?.noiseCancellationProcessorDidUpdateNoiseProfile(self)
    }

    /// Apply noise cancellation to buffer
    func process(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
        guard let floatData = buffer.floatChannelData,
              let noiseFloor = noiseProfile else { return buffer }

        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: buffer.format,
            frameCapacity: buffer.frameCapacity
        )!
        outputBuffer.frameLength = buffer.frameLength

        for channel in 0..<channelCount {
            guard let inSamples = floatData[channel],
                  let outSamples = outputBuffer.floatChannelData?[channel] else { continue }

            for i in 0..<frameCount {
                let sample = inSamples[i]
                let magnitude = abs(sample)
                let threshold = noiseFloor[min(i % noiseFloor.count, noiseFloor.count - 1)]

                if magnitude < threshold * (1.0 + noiseReductionStrength) {
                    outSamples[i] = sample * (1.0 - noiseReductionStrength)
                } else {
                    outSamples[i] = sample
                }
            }
        }

        delegate?.noiseCancellationProcessor(self, didProcessBuffer: outputBuffer, noiseReduced: true)
        return outputBuffer
    }

    /// Reset the learned noise profile
    func resetNoiseProfile() {
        noiseProfile = nil
    }

    /// Simple high-pass filter to remove low-frequency noise (wind, traffic)
    func applyHighPassFilter(to buffer: AVAudioPCMBuffer, cutoffHz: Float = 300) -> AVAudioPCMBuffer {
        guard let floatData = buffer.floatChannelData else { return buffer }
        let sampleRate = Float(buffer.format.sampleRate)
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        let alpha = cutoffHz / (cutoffHz + sampleRate / (2 * .pi))

        let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: buffer.format,
            frameCapacity: buffer.frameCapacity
        )!
        outputBuffer.frameLength = buffer.frameLength

        for channel in 0..<channelCount {
            guard let inSamples = floatData[channel],
                  let outSamples = outputBuffer.floatChannelData?[channel] else { continue }

            var prevIn: Float = 0
            var prevOut: Float = 0
            for i in 0..<frameCount {
                let input = inSamples[i]
                let output = alpha * (prevOut + input - prevIn)
                outSamples[i] = output
                prevIn = input
                prevOut = output
            }
        }

        return outputBuffer
    }
}

protocol NoiseCancellationProcessorDelegate: AnyObject {
    func noiseCancellationProcessorDidUpdateNoiseProfile(_ processor: NoiseCancellationProcessor)
    func noiseCancellationProcessor(_ processor: NoiseCancellationProcessor, didProcessBuffer buffer: AVAudioPCMBuffer, noiseReduced: Bool)
}
