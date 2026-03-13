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
    /// Common dog sound patterns
    static let commonPatterns: [String: [Double]] = [
        "bark": [200.0, 250.0, 300.0, 280.0, 260.0, 240.0], // Bark frequencies
        "whine": [500.0, 480.0, 460.0, 440.0, 420.0, 400.0], // Whine frequencies
        "growl": [150.0, 160.0, 170.0, 180.0, 190.0, 200.0], // Growl frequencies
        "howl": [110.0, 120.0, 130.0, 140.0, 150.0, 160.0] // Howl frequencies
    ]
    
    /// Dog vocalization duration patterns
    static let durationPatterns: [String: ClosedRange<Double>] = [
        "short_bark": 0.3...0.6,
        "medium_bark": 0.6...1.2,
        "long_bark": 1.2...2.5,
        "whine_sequence": 0.2...0.8,
        "growl_sequence": 0.8...1.8,
        "howl_sequence": 2.0...4.0
    ]
    
    /// Natural dog sound characteristics
    static let naturalCharacteristics: [String: [Double]] = [
        "pitch_variation": [0.0, 50.0, 100.0, 75.0, 25.0, 0.0], // Pitch variation over time
        "amplitude_envelope": [0.1, 0.3, 0.6, 0.8, 0.6, 0.3, 0.1], // ADSR envelope
        "formant_modulation": [0.6, 0.55, 0.5, 0.52, 0.58, 0.62, 0.6] // Formant modulation
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