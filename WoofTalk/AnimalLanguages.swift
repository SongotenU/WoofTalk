import Foundation

/// Supported animal languages for translation
enum AnimalLanguage: String, CaseIterable, Codable {
    case dog = "dog"
    case cat = "cat"
    case bird = "bird"
    case rabbit = "rabbit"

    var displayName: String {
        switch self {
        case .dog: return "Dog"
        case .cat: return "Cat"
        case .bird: return "Bird"
        case .rabbit: return "Rabbit"
        }
    }

    var emoji: String {
        switch self {
        case .dog: return "🐕"
        case .cat: return "🐱"
        case .bird: return "🐦"
        case .rabbit: return "🐰"
        }
    }

    var description: String {
        switch self {
        case .dog: return "Dog barks, whines, and howls"
        case .cat: return "Cat meows, purrs, and hisses"
        case .bird: return "Bird chirps, tweets, and sings"
        case .rabbit: return "Rabbit thumps, grunts, and clucks"
        }
    }

    var confidenceThreshold: Double {
        switch self {
        case .dog: return 0.6
        case .cat: return 0.6
        case .bird: return 0.5
        case .rabbit: return 0.5
        }
    }

    var frequencyRange: ClosedRange<Double> {
        switch self {
        case .dog: return 300...3000
        case .cat: return 400...4000
        case .bird: return 1000...8000
        case .rabbit: return 200...2000
        }
    }

    var vocalizationPatterns: [String] {
        switch self {
        case .dog: return ["woof", "bark", "whine", "howl", "growl", "yelp", "sniff"]
        case .cat: return ["meow", "purr", "hiss", "yowl", "chirp", "trill"]
        case .bird: return ["chirp", "tweet", "sing", "squawk", "warble", "call"]
        case .rabbit: return ["thump", "grunt", "cluck", "scream", "purr", "tooth-grind"]
        }
    }
}

/// Extended translation direction supporting multiple animal languages
enum MultiLanguageDirection: Codable, Equatable {
    case humanToAnimal(AnimalLanguage)
    case animalToHuman(AnimalLanguage)

    var sourceLanguage: AnimalLanguage? {
        if case .animalToHuman(let lang) = self { return lang }
        return nil
    }

    var targetLanguage: AnimalLanguage? {
        if case .humanToAnimal(let lang) = self { return lang }
        return nil
    }

    var toLegacyDirection: String? {
        switch (self) {
        case .humanToAnimal(.dog): return "humanToDog"
        case .animalToHuman(.dog): return "dogToHuman"
        default: return nil
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

extension AnimalLanguage {
    func metadata(vocabularySize: Int = 0) -> LanguageMetadata {
        LanguageMetadata(language: self, vocabularySize: vocabularySize)
    }
}
