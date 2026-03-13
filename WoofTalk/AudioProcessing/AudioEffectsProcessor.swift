// MARK: - AudioEffectsProcessor

import AVFoundation

/// Handles audio effects processing for natural dog sound characteristics
final class AudioEffectsProcessor {
    
    // MARK: Properties
    private let audioEngine = AVAudioEngine()
    private let audioFormat = AudioFormats.pcmFormat
    private let effectsQueue = DispatchQueue(label: "com.wooftalk.audioeffects", qos: .userInitiated)
    
    // Dog vocalization parameters
    private let baseDogPitchRange: ClosedRange<Double> = 150...600 // Hz (typical dog vocal range)
    private let formantShiftFactor: Double = 0.6 // Reduce formants for dog-like sound
    private let modulationDepth: Float = 0.3 // Vibrato depth
    private let modulationRate: Double = 5.0 // Hz (vibrato rate)
    
    // MARK: Initialization
    init() {
        setupAudioEngine()
    }
    
    // MARK: Public Methods
    func applyEffects(to buffer: AVAudioPCMBuffer, effects: [AudioEffect]) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else {
            throw AudioEffectsError.formatNotAvailable
        }
        
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
        let dogEffects: [AudioEffect] = [
            .pitchShift(random(in: baseDogPitchRange) - 440.0),
            .formantShift(formantShiftFactor),
            .vibrato(modulationDepth, modulationRate),
            .gain(-10.0)
        ]
        
        return try applyEffects(to: buffer, effects: dogEffects)
    }
    
    // MARK: Audio Effect Processing
    private func applyPitchShift(to buffer: AVAudioPCMBuffer, pitch: Double) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else {
            throw AudioEffectsError.formatNotAvailable
        }
        
        let audioEngine = AVAudioEngine()
        let pitchShift = AVAudioUnitTimePitch()
        pitchShift.pitch = Float(pitch)
        
        audioEngine.attach(pitchShift)
        audioEngine.connect(buffer, to: pitchShift, format: format)
        audioEngine.connect(pitchShift, to: audioEngine.mainMixerNode, format: format)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
            throw AudioEffectsError.bufferCreationFailed
        }
        
        try audioEngine.start()
        pitchShift.render(to: outputBuffer, timing: nil)
        audioEngine.stop()
        
        return outputBuffer
    }
    
    private func applyFormantShift(to buffer: AVAudioPCMBuffer, factor: Double) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else {
            throw AudioEffectsError.formatNotAvailable
        }
        
        let audioEngine = AVAudioEngine()
        let varispeed = AVAudioUnitVarispeed()
        varispeed.rate = Float(factor)
        
        audioEngine.attach(varispeed)
        audioEngine.connect(buffer, to: varispeed, format: format)
        audioEngine.connect(varispeed, to: audioEngine.mainMixerNode, format: format)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
            throw AudioEffectsError.bufferCreationFailed
        }
        
        try audioEngine.start()
        varispeed.render(to: outputBuffer, timing: nil)
        audioEngine.stop()
        
        return outputBuffer
    }
    
    private func applyVibrato(to buffer: AVAudioPCMBuffer, depth: Float, rate: Double) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else {
            throw AudioEffectsError.formatNotAvailable
        }
        
        let audioEngine = AVAudioEngine()
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.0
        delay.feedback = 0.0
        delay.wetDryMix = 100.0
        delay.lfoFrequency = Float(rate)
        delay.lfoDepth = depth
        
        audioEngine.attach(delay)
        audioEngine.connect(buffer, to: delay, format: format)
        audioEngine.connect(delay, to: audioEngine.mainMixerNode, format: format)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
            throw AudioEffectsError.bufferCreationFailed
        }
        
        try audioEngine.start()
        delay.render(to: outputBuffer, timing: nil)
        audioEngine.stop()
        
        return outputBuffer
    }
    
    private func applyGain(to buffer: AVAudioPCMBuffer, gain: Float) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else {
            throw AudioEffectsError.formatNotAvailable
        }
        
        let audioEngine = AVAudioEngine()
        let mixer = AVAudioMixerNode()
        mixer.volume = gain
        
        audioEngine.attach(mixer)
        audioEngine.connect(buffer, to: mixer, format: format)
        audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: format)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
            throw AudioEffectsError.bufferCreationFailed
        }
        
        try audioEngine.start()
        mixer.render(to: outputBuffer, timing: nil)
        audioEngine.stop()
        
        return outputBuffer
    }
    
    private func applyCompression(to buffer: AVAudioPCMBuffer, threshold: Float, ratio: Float) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else {
            throw AudioEffectsError.formatNotAvailable
        }
        
        let audioEngine = AVAudioEngine()
        let compressor = AVAudioUnitCompressor()
        compressor.threshold = threshold
        compressor.ratio = ratio
        
        audioEngine.attach(compressor)
        audioEngine.connect(buffer, to: compressor, format: format)
        audioEngine.connect(compressor, to: audioEngine.mainMixerNode, format: format)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
            throw AudioEffectsError.bufferCreationFailed
        }
        
        try audioEngine.start()
        compressor.render(to: outputBuffer, timing: nil)
        audioEngine.stop()
        
        return outputBuffer
    }
    
    private func applyDistortion(to buffer: AVAudioPCMBuffer, amount: Float) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else {
            throw AudioEffectsError.formatNotAvailable
        }
        
        let audioEngine = AVAudioEngine()
        let distortion = AVAudioUnitDistortion()
        distortion.preGain = amount
        distortion.wetDryMix = 100.0
        
        audioEngine.attach(distortion)
        audioEngine.connect(buffer, to: distortion, format: format)
        audioEngine.connect(distortion, to: audioEngine.mainMixerNode, format: format)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
            throw AudioEffectsError.bufferCreationFailed
        }
        
        try audioEngine.start()
        distortion.render(to: outputBuffer, timing: nil)
        audioEngine.stop()
        
        return outputBuffer
    }
    
    private func applyDogVocalization(to buffer: AVAudioPCMBuffer) throws -> AVAudioPCMBuffer {
        // Apply multiple dog-specific effects
        var currentBuffer = try applyPitchShift(to: buffer, pitch: random(in: baseDogPitchRange) - 440.0)
        currentBuffer = try applyFormantShift(to: currentBuffer, factor: formantShiftFactor)
        currentBuffer = try applyVibrato(to: currentBuffer, depth: modulationDepth, rate: modulationRate)
        currentBuffer = try applyGain(to: currentBuffer, gain: -10.0)
        currentBuffer = try applyCompression(to: currentBuffer, threshold: -25.0, ratio: 5.0)
        
        return currentBuffer
    }
    
    // MARK: Audio Engine Setup
    private func setupAudioEngine() {
        // Basic audio engine setup for effects processing
        audioEngine.mainMixerNode.volume = 0.0
    }
    
    // MARK: Audio Information
    func getEffectsStatistics() -> (pitch: Double, formantShift: Double, modulation: Double) {
        return (random(in: baseDogPitchRange), formantShiftFactor, modulationRate)
    }
    
    func isEffectsAvailable() -> Bool {
        return true // Effects are always available
    }
}

// MARK: - AudioEffectsProcessor Errors

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

// MARK: - AudioEffect Types

enum AudioEffect {
    case pitchShift(Double) // Pitch shift in cents
    case formantShift(Double) // Formant shift factor (0.5 = half speed, 2.0 = double speed)
    case vibrato(Float, Double) // Depth and rate
    case gain(Float) // Gain in dB
    case compression(Float, Float) // Threshold and ratio
    case distortion(Float) // Distortion amount
    case dogVocalization // Predefined dog vocalization effects
}

// MARK: - Utility Functions

extension AudioEffectsProcessor {
    private func random(in range: ClosedRange<Double>) -> Double {
        return Double.random(in: range)
    }
    
    private func random(in range: ClosedRange<Float>) -> Float {
        return Float.random(in: range)
    }
    
    private func random(in range: ClosedRange<Int>) -> Int {
        return Int.random(in: range)
    }
    
    func getSupportedEffects() -> [AudioEffect] {
        return [
            .pitchShift(0.0),
            .formantShift(1.0),
            .vibrato(0.0, 0.0),
            .gain(0.0),
            .compression(0.0, 0.0),
            .distortion(0.0),
            .dogVocalization
        ]
    }
    
    func getEffectDescriptions() -> [String] {
        return [
            "Pitch Shift: Changes the pitch of the audio",
            "Formant Shift: Changes the vocal tract characteristics",
            "Vibrato: Adds pitch modulation",
            "Gain: Adjusts volume",
            "Compression: Reduces dynamic range",
            "Distortion: Adds audio distortion",
            "Dog Vocalization: Applies dog-specific effects"
        ]
    }
}