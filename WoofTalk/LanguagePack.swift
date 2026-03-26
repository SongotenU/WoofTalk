import Foundation

// MARK: - LanguagePack

struct LanguagePack {

/// Vocabulary pack containing translations for an animal language
struct LanguagePack: Codable {
    let language: AnimalLanguage
    let humanToAnimal: [String: String]
    let animalToHuman: [String: String]
    let audioPatterns: [String]
    let metadata: PackMetadata
    
    struct PackMetadata: Codable {
        let version: String
        let phraseCount: Int
        let lastUpdated: Date
    }
    
    var vocabularySize: Int {
        return humanToAnimal.count + animalToHuman.count
    }
}

/// Manager for loading and accessing language packs
final class LanguagePackManager {
    static let shared = LanguagePackManager()
    
    private var loadedPacks: [AnimalLanguage: LanguagePack] = [:]
    private let packQueue = DispatchQueue(label: "com.wooftalk.languagepack", qos: .userInitiated)
    
    private init() {
        loadDefaultPacks()
    }
    
    func getPack(for language: AnimalLanguage) -> LanguagePack? {
        return loadedPacks[language]
    }
    
    func loadPack(for language: AnimalLanguage) {
        packQueue.async { [weak self] in
            guard let self = self else { return }
            if self.loadedPacks[language] == nil {
                self.loadedPacks[language] = self.createDefaultPack(for: language)
            }
        }
    }
    
    func getAllPacks() -> [AnimalLanguage: LanguagePack] {
        return loadedPacks
    }
    
    func vocabularySize(for language: AnimalLanguage) -> Int {
        return loadedPacks[language]?.vocabularySize ?? 0
    }
    
    private func loadDefaultPacks() {
        for language in AnimalLanguage.allCases {
            loadedPacks[language] = createDefaultPack(for: language)
        }
    }
    
    private func createDefaultPack(for language: AnimalLanguage) -> LanguagePack {
        switch language {
        case .dog:
            return LanguagePack(
                language: .dog,
                humanToAnimal: [
                    "hello": "Woof woof!",
                    "good boy": "Tail wag! I'm a good boy!",
                    "good girl": "Tail wag! I'm a good girl!",
                    "sit": "Woof woof (sitting)",
                    "stay": "Woof woof woof woof",
                    "come": "Coming to you! Woof!",
                    "food": "Yum! Food time!",
                    "walk": "Walk! Walk! Let's go!",
                    "play": "Play time! Fetch!",
                    "ball": "Ball! Throw the ball!",
                    "treat": "Treat! I want a treat!",
                    "outside": "Outside! I need to go out!",
                    "no": "Woof... (understanding)",
                    "yes": "Yes! I understand!",
                    "love you": "Love you! Lick!",
                    "good morning": "Morning! Woof woof!",
                    "good night": "Night night! Zzz"
                ],
                animalToHuman: [
                    "woof woof": "Hello! I'm happy to see you!",
                    "woof woof woof": "Let's go for a walk!",
                    "woof woof woof woof": "I need to go outside!",
                    "whine whine": "I'm worried or anxious",
                    "bark bark": "Alert! Something is happening",
                    "growl": "I'm warning you to stay back",
                    "howl": "I'm calling for my pack / I miss you",
                    "whimper": "I'm in pain or seeking attention",
                    "yelp": "Ouch! That hurt!",
                    "sniff sniff": "I'm investigating a scent",
                    "tail wag": "I'm happy!",
                    "whine": "I want something / I'm not sure"
                ],
                audioPatterns: ["woof", "bark", "whine", "howl", "growl", "yelp"],
                metadata: PackMetadata(version: "1.0.0", phraseCount: 28, lastUpdated: Date())
            )
            
        case .cat:
            return LanguagePack(
                language: .cat,
                humanToAnimal: [
                    "hello": "Meow!",
                    "good boy": "Purr... I love you",
                    "good girl": "Purr... I'm the best",
                    "sit": "Meow (sitting)",
                    "food": "Meow! Food please!",
                    "play": "Chase! Toy time!",
                    "treat": "Treat! Give me treat!",
                    "outside": "Meow! Let me out!",
                    "no": "Hiss... (understood)",
                    "yes": "Meow! Yes!",
                    "love you": "Purr... love you",
                    "good morning": "Meow! Morning!",
                    "good night": "Purr... good night"
                ],
                animalToHuman: [
                    "meow": "Hello! I want attention!",
                    "meow meow": "I'm hungry!",
                    "purr": "I'm content and happy",
                    "hiss": "Stay away! I'm scared/angry",
                    "yowl": "I'm lonely or in heat",
                    "chirp": "I see prey! Interesting!",
                    "trill": "Hello! Happy to see you!",
                    "growl": "Stop! Don't touch me!",
                    "meow meow meow": "Let me out please!"
                ],
                audioPatterns: ["meow", "purr", "hiss", "yowl", "chirp", "trill"],
                metadata: PackMetadata(version: "1.0.0", phraseCount: 20, lastUpdated: Date())
            )
            
        case .bird:
            return LanguagePack(
                language: .bird,
                humanToAnimal: [
                    "hello": "Chirp! Hello!",
                    "good bird": "Tweet tweet! I'm good!",
                    "sit": "Chirp (perching)",
                    "food": "Chirp! Seeds please!",
                    "play": "Chirp chirp! Play time!",
                    "treat": "Treat! Yummy!",
                    "come": "Tweet! Coming!",
                    "no": "Chirp... (understood)",
                    "yes": "Tweet! Yes!",
                    "good morning": "Tweet! Morning!",
                    "good night": "Chirp... night night"
                ],
                animalToHuman: [
                    "chirp chirp": "Hello! I'm here!",
                    "tweet tweet": "I'm happy!",
                    "sing": "I'm singing! Listen!",
                    "squawk": "Alert! Something wrong!",
                    "warble": "I'm practicing my song!",
                    "call": "Hey! Over here!",
                    "chirp": "I'm just checking in",
                    "tweet": "Everything's okay!"
                ],
                audioPatterns: ["chirp", "tweet", "sing", "squawk", "warble", "call"],
                metadata: PackMetadata(version: "1.0.0", phraseCount: 16, lastUpdated: Date())
            )
        }
    }
}

/// Extension to get pack from AnimalLanguage
extension AnimalLanguage {
    var pack: LanguagePack? {
        return LanguagePackManager.shared.getPack(for: self)
    }
}
