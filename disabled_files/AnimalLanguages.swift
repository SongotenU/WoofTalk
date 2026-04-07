// MARK: - AnimalLanguages

import Foundation

/// Supported animal languages for translation
enum AnimalLanguage: String, CaseIterable, Codable {
    case dog = "dog"
    case cat = "cat"
    case bird = "bird"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        case .bird: return "Bird"
        }
    }
    
    /// Emoji representation
    var emoji: String {
        switch self {
        case .dog: return "🐕"
        case .cat: return "🐱"
        case .bird: return "🐦"
        }
    }
    
    /// Description of the animal language
    var description: String {
        switch self {
        case .dog: return "Dog barks, whines, and howls"
        case .cat: return "Cat meows, purrs, and hisses"
        case .bird: return "Bird chirps, tweets, and sings"
        }
    }
    
    /// Confidence threshold for auto-detection
    var confidenceThreshold: Double {
        switch self {
        case .dog: return 0.6
        case .cat: return 0.6
        case .bird: return 0.5
        }
    }
    
    /// Audio frequency range for this animal (Hz)
    var frequencyRange: ClosedRange<Double> {
        switch self {
        case .dog: return 300...3000
        case .cat: return 400...4000
        case .bird: return 1000...8000
        }
    }
    
    /// Typical vocalization patterns
    var vocalizationPatterns: [String] {
        switch self {
        case .dog:
            return ["woof", "bark", "whine", "howl", "growl", "yelp", "sniff"]
        case .cat:
            return ["meow", "purr", "hiss", "yowl", "chirp", "trill"]
        case .bird:
            return ["chirp", "tweet", "sing", "squawk", "warble", "call"]
        }
    }
}

/// Extended translation direction supporting multiple animal languages
enum MultiLanguageDirection: Codable, Equatable {
    case humanToAnimal(AnimalLanguage)
    case animalToHuman(AnimalLanguage)
    
    var sourceLanguage: AnimalLanguage? {
        switch self {
        case .humanToAnimal(let lang):
            return nil // Human is source
        case .animalToHuman(let lang):
            return lang
        }
    }
    
    var targetLanguage: AnimalLanguage? {
        switch self {
        case .humanToAnimal(let lang):
            return lang
        case .animalToHuman:
            return nil // Human is target
        }
    }
    
    /// Legacy conversion for compatibility (returns nil if not a dog language)
    var toLegacyDirection: String? {
        switch self {
        case .humanToAnimal(.dog), .animalToHuman(.dog):
            return self == .humanToAnimal(.dog) ? "humanToDog" : "dogToHuman"
        default:
            return nil
        }
    }
}

/// Language metadata for display and configuration
struct LanguageMetadata: Codable, Identifiable {
    let id: String
    let language: AnimalLanguage
    let displayName: String
    let emoji: String
    let description: String
    let vocabularySize: Int
    let isAvailable: Bool
    
    init(language: AnimalLanguage, vocabularySize: Int = 0, isAvailable: Bool = true) {
        self.id = language.rawValue
        self.language = language
        self.displayName = language.displayName
        self.emoji = language.emoji
        self.description = language.description
        self.vocabularySize = vocabularySize
        self.isAvailable = isAvailable
    }
}

/// Extension to create metadata from language
extension AnimalLanguage {
    func metadata(vocabularySize: Int = 0) -> LanguageMetadata {
        return LanguageMetadata(language: self, vocabularySize: vocabularySize)
    }
}
