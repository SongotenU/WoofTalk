import AVFoundation

final class AudioSynthesis {
    func generateTone(frequency: Double, duration: TimeInterval, amplitude: Float = 0.5,
                     waveform: Waveform = .sine) throws -> AVAudioPCMBuffer {
        let format = AudioFormats.pcmFormat
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioSynthesisError.bufferCreationFailed
        }

        let channelCount = Int(format.channelCount)
        let phaseIncrement = 2.0 * Double.pi * frequency / sampleRate

        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            var phase: Double = 0

            switch waveform {
            case .sine:
                for frame in 0..<Int(frameCount) {
                    channelData[frame] = Float(sin(phase) * Double(amplitude))
                    phase += phaseIncrement
                }
            case .square:
                for frame in 0..<Int(frameCount) {
                    channelData[frame] = (sin(phase) >= 0) ? amplitude : -amplitude
                    phase += phaseIncrement
                }
            case .sawtooth:
                for frame in 0..<Int(frameCount) {
                    channelData[frame] = Float((phase / (2.0 * Double.pi) - 0.5) * 2.0 * Double(amplitude))
                    phase += phaseIncrement
                }
            case .triangle:
                for frame in 0..<Int(frameCount) {
                    let normalizedPhase = phase / (2.0 * Double.pi)
                    channelData[frame] = Float((abs(normalizedPhase - 0.5) - 0.25) * 4.0 * Double(amplitude))
                    phase += phaseIncrement
                }
            case .noise:
                for frame in 0..<Int(frameCount) {
                    channelData[frame] = Float(Double.random(in: -1.0...1.0) * Double(amplitude))
                }
            }
        }

        buffer.frameLength = frameCount
        return buffer
    }

    func generateClickTrack(bpm: Double, duration: TimeInterval,
                            beatsPerMeasure: Int = 4, accentFrequency: Double = 880.0) throws -> AVAudioPCMBuffer {
        let format = AudioFormats.pcmFormat
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioSynthesisError.bufferCreationFailed
        }

        let channelCount = Int(format.channelCount)
        let samplesPerBeat = sampleRate * 60.0 / bpm

        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }

            for frame in 0..<Int(frameCount) {
                let beatPosition = Double(frame) / sampleRate
                let beatNumber = Int(beatPosition / (60.0 / bpm)) % beatsPerMeasure
                let beatProgress = beatPosition.truncatingRemainder(dividingBy: 60.0 / bpm) / (60.0 / bpm)

                let frequency = (beatNumber == 0) ? accentFrequency : 440.0
                let phase = 2.0 * Double.pi * frequency * beatProgress
                channelData[frame] = Float(sin(phase) * 0.3 * (1.0 - beatProgress * 4.0))
            }
        }

        buffer.frameLength = frameCount
        return buffer
    }

    func generateSilence(duration: TimeInterval) throws -> AVAudioPCMBuffer {
        let format = AudioFormats.pcmFormat
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioSynthesisError.bufferCreationFailed
        }

        let channelCount = Int(format.channelCount)

        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<Int(frameCount) {
                channelData[frame] = 0.0
            }
        }

        buffer.frameLength = frameCount
        return buffer
    }

    func applyReverb(to buffer: AVAudioPCMBuffer, wetDryMix: Float = 50.0) throws -> AVAudioPCMBuffer {
        let reverb = AVAudioUnitReverb()
        reverb.wetDryMix = wetDryMix
        return try render(buffer: buffer, node: reverb)
    }

    func applyEqualization(to buffer: AVAudioPCMBuffer,
                          bassGain: Float = 0.0, trebleGain: Float = 0.0) throws -> AVAudioPCMBuffer {
        let eq = AVAudioUnitEQ(numberOfBands: 2)
        eq.bands[0].filterType = .lowPass
        eq.bands[0].frequency = 200
        eq.bands[0].gain = bassGain
        eq.bands[1].filterType = .highPass
        eq.bands[1].frequency = 5000
        eq.bands[1].gain = trebleGain
        return try render(buffer: buffer, node: eq)
    }

    private func render(buffer: AVAudioPCMBuffer, node: AVAudioNode) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else {
            throw AudioSynthesisError.formatNotAvailable
        }

        let engine = AVAudioEngine()
        engine.attach(node)
        engine.connect(buffer, to: node, format: format)
        engine.connect(node, to: engine.mainMixerNode, format: format)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
            throw AudioSynthesisError.bufferCreationFailed
        }

        try engine.start()
        node.render(to: outputBuffer, timing: nil)
        engine.stop()

        return outputBuffer
    }
}

enum AudioSynthesisError: Error, LocalizedError {
    case formatNotAvailable
    case bufferCreationFailed
    case audioEngineConfigurationFailed

    var errorDescription: String? {
        switch self {
        case .formatNotAvailable: return "Audio format not available"
        case .bufferCreationFailed: return "Audio buffer creation failed"
        case .audioEngineConfigurationFailed: return "Audio engine configuration failed"
        }
    }
}

enum Waveform {
    case sine
    case square
    case sawtooth
    case triangle
    case noise
}
