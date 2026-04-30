// MARK: - Synthesis Models

import AVFoundation

/// Dog emotion types with corresponding vocalization characteristics
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

/// Parameters for dog vocalization synthesis based on emotion
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

/// Quality metrics for dog vocalization synthesis
struct DogSynthesisMetrics {
    let pitchAccuracy: Double // 0.0 to 1.0
    let formantQuality: Double // 0.0 to 1.0
    let vibratoAuthenticity: Double // 0.0 to 1.0
    let overallQuality: Double // 0.0 to 1.0
    
    var qualityDescription: String {
        switch overallQuality {
        case 0.9...: return "Excellent - Highly realistic dog vocalizations"
        case 0.8..<0.9: return "Good - Natural-sounding dog vocalizations"
        case 0.7..<0.8: return "Fair - Recognizable but synthetic dog sounds"
        default: return "Poor - Needs improvement in vocalization quality"
        }
    }
}

/// Audio effect types for dog vocalization processing
enum AudioEffect {
    case pitchShift(Double) // Pitch shift in cents
    case formantShift(Double) // Formant shift factor
    case vibrato(Float, Double) // Depth, rate
    case gain(Float) // Volume adjustment
    case compression(Double, Double) // Threshold, ratio
    case distortion(Double) // Distortion amount
    case dogVocalization // Predefined dog effects
}

/// Dog vocalization audio models and patterns
struct DogVocalizationModels {
    static let commonPatterns: [String: [Double]] = [
        "bark": [200, 250, 300, 280, 260, 240],
        "whine": [500, 480, 460, 440, 420, 400],
        "growl": [150, 160, 170, 180, 190, 200],
        "howl": [110, 120, 130, 140, 150, 160]
    ]

    static let durationPatterns: [String: ClosedRange<Double>] = [
        "short_bark": 0.3...0.6, "medium_bark": 0.6...1.2, "long_bark": 1.2...2.5,
        "whine_sequence": 0.2...0.8, "growl_sequence": 0.8...1.8, "howl_sequence": 2.0...4.0
    ]

    static let naturalCharacteristics: [String: [Double]] = [
        "pitch_variation": [0, 50, 100, 75, 25, 0],
        "amplitude_envelope": [0.1, 0.3, 0.6, 0.8, 0.6, 0.3, 0.1],
        "formant_modulation": [0.6, 0.55, 0.5, 0.52, 0.58, 0.62, 0.6]
    ]
}

/// Predefined dog vocalization presets
struct DogVocalizationPresets {
    static let defaultDog = DogVocalizationParameters(
        pitchRange: 250...450,
        formantShift: 0.5,
        vibratoDepth: 0.2,
        vibratoRate: 3.0,
        modulationDepth: 0.1,
        modulationRate: 2.0,
        amplitudeRange: 0.3...0.6,
        durationRange: 1.0...3.0
    )
    
    static let happyDog = DogVocalizationParameters(
        pitchRange: 300...600,
        formantShift: 0.4,
        vibratoDepth: 0.25,
        vibratoRate: 4.0,
        modulationDepth: 0.15,
        modulationRate: 2.5,
        amplitudeRange: 0.5...0.8,
        durationRange: 0.8...2.5
    )
    
    static let excitedDog = DogVocalizationParameters(
        pitchRange: 250...700,
        formantShift: 0.4,
        vibratoDepth: 0.2,
        vibratoRate: 4.0,
        modulationDepth: 0.15,
        modulationRate: 3.0,
        amplitudeRange: 0.4...0.8,
        durationRange: 2.0...6.0
    )
    
    static let scaredDog = DogVocalizationParameters(
        pitchRange: 400...650,
        formantShift: 0.3,
        vibratoDepth: 0.4,
        vibratoRate: 6.0,
        modulationDepth: 0.25,
        modulationRate: 4.0,
        amplitudeRange: 0.2...0.5,
        durationRange: 0.5...2.0
    )
    
    static let aggressiveDog = DogVocalizationParameters(
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