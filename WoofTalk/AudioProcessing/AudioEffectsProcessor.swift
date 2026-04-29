import AVFoundation

/// Handles audio effects processing for natural dog sound characteristics
final class AudioEffectsProcessor {
    private let baseDogPitchRange: ClosedRange<Double> = 150...600
    private let formantShiftFactor: Double = 0.6
    private let modulationDepth: Float = 0.3
    private let modulationRate: Double = 5.0

    func applyEffects(to buffer: AVAudioPCMBuffer, effects: [AudioEffect]) throws -> AVAudioPCMBuffer {
        var currentBuffer = buffer

        for effect in effects {
            switch effect {
            case .pitchShift(let pitch):
                currentBuffer = try applyPitchShift(to: currentBuffer, pitch: pitch)
            case .formantShift(let factor):
                currentBuffer = try applyFormantShift(to: currentBuffer, factor: factor)
            case .vibrato(let depth, let rate):
                currentBuffer = try applyVibrato(to: currentBuffer, depth: depth, rate: rate)
            case .gain(let gain):
                currentBuffer = try applyGain(to: currentBuffer, gain: gain)
            case .compression(let threshold, let ratio):
                currentBuffer = try applyCompression(to: currentBuffer, threshold: threshold, ratio: ratio)
            case .distortion(let amount):
                currentBuffer = try applyDistortion(to: currentBuffer, amount: amount)
            case .dogVocalization:
                currentBuffer = try applyDogVocalization(to: currentBuffer)
            }
        }

        return currentBuffer
    }

    func applyDogVocalizationEffects(to buffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        try applyDogVocalization(to: buffer)
    }

    // MARK: - Private Effect Methods

    private func applyPitchShift(to buffer: AVAudioPCMBuffer, pitch: Double) throws -> AVAudioPCMBuffer {
        let pitchShift = AVAudioUnitTimePitch()
        pitchShift.pitch = Float(pitch)
        return try render(buffer: buffer, node: pitchShift)
    }

    private func applyFormantShift(to buffer: AVAudioPCMBuffer, factor: Double) throws -> AVAudioPCMBuffer {
        let varispeed = AVAudioUnitVarispeed()
        varispeed.rate = Float(factor)
        return try render(buffer: buffer, node: varispeed)
    }

    private func applyVibrato(to buffer: AVAudioPCMBuffer, depth: Float, rate: Double) throws -> AVAudioPCMBuffer {
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.0
        delay.feedback = 0.0
        delay.wetDryMix = 100.0
        delay.lfoFrequency = Float(rate)
        delay.lfoDepth = depth
        return try render(buffer: buffer, node: delay)
    }

    private func applyGain(to buffer: AVAudioPCMBuffer, gain: Float) throws -> AVAudioPCMBuffer {
        let mixer = AVAudioMixerNode()
        mixer.volume = gain
        return try render(buffer: buffer, node: mixer)
    }

    private func applyCompression(to buffer: AVAudioPCMBuffer, threshold: Float, ratio: Float) throws -> AVAudioPCMBuffer {
        let compressor = AVAudioUnitCompressor()
        compressor.threshold = threshold
        compressor.ratio = ratio
        return try render(buffer: buffer, node: compressor)
    }

    private func applyDistortion(to buffer: AVAudioPCMBuffer, amount: Float) throws -> AVAudioPCMBuffer {
        let distortion = AVAudioUnitDistortion()
        distortion.preGain = amount
        distortion.wetDryMix = 100.0
        return try render(buffer: buffer, node: distortion)
    }

    private func applyDogVocalization(to buffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        let pitch = Double.random(in: baseDogPitchRange) - 440.0
        return try applyEffects(to: buffer, effects: [
            .pitchShift(pitch),
            .formantShift(formantShiftFactor),
            .vibrato(modulationDepth, modulationRate),
            .gain(-10.0),
            .compression(-25.0, 5.0)
        ])
    }

    // MARK: - Private Helpers

    private func render(buffer: AVAudioPCMBuffer, node: AVAudioNode) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else {
            throw AudioEffectsError.formatNotAvailable
        }

        let engine = AVAudioEngine()
        engine.attach(node)
        engine.connect(buffer, to: node, format: format)
        engine.connect(node, to: engine.mainMixerNode, format: format)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
            throw AudioEffectsError.bufferCreationFailed
        }

        try engine.start()
        node.render(to: outputBuffer, timing: nil)
        engine.stop()

        return outputBuffer
    }
}

enum AudioEffectsError: Error, LocalizedError {
    case formatNotAvailable
    case bufferCreationFailed
    case audioEngineConfigurationFailed
    case effectProcessingFailed
    case invalidParameters

    var errorDescription: String? {
        switch self {
        case .formatNotAvailable:
            return "Audio format not available for effects processing"
        case .bufferCreationFailed:
            return "Audio buffer creation failed for effects processing"
        case .audioEngineConfigurationFailed:
            return "Audio engine configuration failed for effects processing"
        case .effectProcessingFailed:
            return "Audio effect processing failed"
        case .invalidParameters:
            return "Invalid parameters for audio effects processing"
        }
    }
}

enum AudioEffect {
    case pitchShift(Double)
    case formantShift(Double)
    case vibrato(Float, Double)
    case gain(Float)
    case compression(Float, Float)
    case distortion(Float)
    case dogVocalization
}
