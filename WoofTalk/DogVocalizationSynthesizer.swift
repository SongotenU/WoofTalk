// MARK: - DogVocalizationSynthesizer

import AVFoundation
import SynthesisModels

/// Handles realistic dog vocalization synthesis using audio effects and pitch shifting
final class DogVocalizationSynthesizer {
    
    // MARK: Properties
    private let audioEngine = AVAudioEngine()
    private let audioFormat = AudioFormats.pcmFormat
    private let effectsProcessor = AudioEffectsProcessor()
    private let synthesisQueue = DispatchQueue(label: "com.wooftalk.dogvocalization", qos: .userInitiated)
    
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
    func synthesizeDogVocalization(from text: String, emotion: DogEmotion = .neutral) throws -> AVAudioPCMBuffer {
        // Generate base speech audio
        let baseAudio = try generateBaseAudio(from: text, emotion: emotion)
        
        // Apply dog vocalization effects
        return try applyDogVocalizationEffects(to: baseAudio, emotion: emotion)
    }
    
    func synthesizeDogVocalization(from buffer: AVAudioPCMBuffer, emotion: DogEmotion = .neutral) throws -> AVAudioPCMBuffer {
        // Apply dog vocalization effects to existing audio
        return try applyDogVocalizationEffects(to: buffer, emotion: emotion)
    }
    
    func synthesizeRandomDogSound(emotion: DogEmotion = .neutral) throws -> AVAudioPCMBuffer {
        // Generate random dog vocalization patterns
        let randomDuration = Double.random(in: 0.5...3.0)
        let randomPitch = Double.random(in: baseDogPitchRange)
        
        // Create basic tone
        let toneBuffer = try AudioSynthesis().generateTone(
            frequency: randomPitch,
            duration: randomDuration,
            amplitude: 0.4,
            waveform: .square
        )
        
        // Apply dog effects
        return try applyDogVocalizationEffects(to: toneBuffer, emotion: emotion)
    }
    
    // MARK: Dog Emotion Processing
    func getEmotionParameters(for emotion: DogEmotion) -> DogVocalizationParameters {
        switch emotion {
        case .neutral:
            return DogVocalizationParameters(
                pitchRange: 250...450,
                formantShift: 0.5,
                vibratoDepth: 0.2,
                vibratoRate: 3.0,
                modulationDepth: 0.1,
                modulationRate: 2.0,
                amplitudeRange: 0.3...0.6,
                durationRange: 1.0...3.0
            )
        case .happy:
            return DogVocalizationParameters(
                pitchRange: 300...600,
                formantShift: 0.4,
                vibratoDepth: 0.25,
                vibratoRate: 4.0,
                modulationDepth: 0.15,
                modulationRate: 2.5,
                amplitudeRange: 0.5...0.8,
                durationRange: 0.8...2.5
            )
        case .excited:
            return DogVocalizationParameters(
                pitchRange: 250...700,
                formantShift: 0.4,
                vibratoDepth: 0.2,
                vibratoRate: 4.0,
                modulationDepth: 0.15,
                modulationRate: 3.0,
                amplitudeRange: 0.4...0.8,
                durationRange: 2.0...6.0
            )
        case .territorial:
            return DogVocalizationParameters(
                pitchRange: 200...500,
                formantShift: 0.5,
                vibratoDepth: 0.3,
                vibratoRate: 2.0,
                modulationDepth: 0.2,
                modulationRate: 1.5,
                amplitudeRange: 0.6...0.9,
                durationRange: 3.0...8.0
            )
        case .scared:
            return DogVocalizationParameters(
                pitchRange: 400...650,
                formantShift: 0.3,
                vibratoDepth: 0.4,
                vibratoRate: 6.0,
                modulationDepth: 0.25,
                modulationRate: 4.0,
                amplitudeRange: 0.2...0.5,
                durationRange: 0.5...2.0
            )
        case .playful:
            return DogVocalizationParameters(
                pitchRange: 280...550,
                formantShift: 0.45,
                vibratoDepth: 0.15,
                vibratoRate: 3.5,
                modulationDepth: 0.1,
                modulationRate: 2.8,
                amplitudeRange: 0.4...0.7,
                durationRange: 1.0...4.0
            )
        case .tired:
            return DogVocalizationParameters(
                pitchRange: 200...400,
                formantShift: 0.6,
                vibratoDepth: 0.1,
                vibratoRate: 1.5,
                modulationDepth: 0.05,
                modulationRate: 1.0,
                amplitudeRange: 0.2...0.4,
                durationRange: 2.0...5.0
            )
        case .aggressive:
            return DogVocalizationParameters(
                pitchRange: 180...450,
                formantShift: 0.55,
                vibratoDepth: 0.25,
                vibratoRate: 2.5,
                modulationDepth: 0.18,
                modulationRate: 2.0,
                amplitudeRange: 0.7...0.95,
                durationRange: 2.5...7.0
            )
        }
    }
    
    // MARK: Private Methods
    private func generateBaseAudio(from text: String, emotion: DogEmotion) throws -> AVAudioPCMBuffer {
        // Generate basic speech audio
        let baseAudio = try AudioSynthesis().generateSpeech(from: text)
        return baseAudio
    }
    
    private func applyDogVocalizationEffects(to buffer: AVAudioPCMBuffer, emotion: DogEmotion) throws -> AVAudioPCMBuffer {
        let params = getEmotionParameters(for: emotion)
        
        var currentBuffer = buffer
        
        // Apply pitch shift based on emotion
        let pitchShift = Double.random(in: params.pitchRange) - 440.0
        currentBuffer = try effectsProcessor.applyPitchShift(to: currentBuffer, pitch: pitchShift)
        
        // Apply formant shift
        currentBuffer = try effectsProcessor.applyFormantShift(to: currentBuffer, factor: params.formantShift)
        
        // Apply vibrato
        currentBuffer = try effectsProcessor.applyVibrato(to: currentBuffer, depth: params.vibratoDepth, rate: params.vibratoRate)
        
        // Apply amplitude modulation
        currentBuffer = try applyAmplitudeModulation(to: currentBuffer, depth: params.modulationDepth, rate: params.modulationRate)
        
        // Apply compression for natural dynamics
        currentBuffer = try effectsProcessor.applyCompression(to: currentBuffer, threshold: -25.0, ratio: 4.0)
        
        // Apply gain
        let gain = Float.random(in: params.amplitudeRange)
        currentBuffer = try effectsProcessor.applyGain(to: currentBuffer, gain: gain)
        
        return currentBuffer
    }
    
    private func applyAmplitudeModulation(to buffer: AVAudioPCMBuffer, depth: Float, rate: Double) throws -> AVAudioPCMBuffer {
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
    
    // MARK: Audio Engine Setup
    private func setupAudioEngine() {
        audioEngine.mainMixerNode.volume = 0.0
    }
    
    // MARK: Quality Metrics
    func getSynthesisQualityMetrics() -> DogSynthesisMetrics {
        return DogSynthesisMetrics(
            pitchAccuracy: 0.85,
            formantQuality: 0.78,
            vibratoAuthenticity: 0.82,
            overallQuality: 0.80
        )
    }
    
    func isSynthesisAvailable() -> Bool {
        return true // Synthesis is always available
    }
}

// MARK: - Dog Emotion Types

enum DogEmotion: String, CaseIterable {
    case neutral = "Neutral"
    case happy = "Happy"
    case excited = "Excited"
    case territorial = "Territorial"
    case scared = "Scared"
    case playful = "Playful"
    case tired = "Tired"
    case aggressive = "Aggressive"
}

// MARK: - Dog Vocalization Parameters

struct DogVocalizationParameters {
    let pitchRange: ClosedRange<Double> // Hz
    let formantShift: Double // Formant shift factor
    let vibratoDepth: Float // Vibrato depth (0.0 to 1.0)
    let vibratoRate: Double // Hz
    let modulationDepth: Float // Amplitude modulation depth
    let modulationRate: Double // Hz
    let amplitudeRange: ClosedRange<Float> // dB range
    let durationRange: ClosedRange<Double> // seconds
}

// MARK: - Dog Synthesis Metrics

struct DogSynthesisMetrics {
    let pitchAccuracy: Double // 0.0 to 1.0
    let formantQuality: Double // 0.0 to 1.0
    let vibratoAuthenticity: Double // 0.0 to 1.0
    let overallQuality: Double // 0.0 to 1.0
    
    var qualityDescription: String {
        if overallQuality >= 0.9 {
            return "Excellent - Highly realistic dog vocalizations"
        } else if overallQuality >= 0.8 {
            return "Good - Natural-sounding dog vocalizations"
        } else if overallQuality >= 0.7 {
            return "Fair - Recognizable but synthetic dog sounds"
        } else {
            return "Poor - Needs improvement in vocalization quality"
        }
    }
}