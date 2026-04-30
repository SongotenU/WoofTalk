import Foundation

final class MultiLanguageAdapter {
    static let shared = MultiLanguageAdapter()

    private let aiService: AITranslationService
    private var languageAdapters: [AnimalLanguage: LanguageAdapterProtocol] = [:]

    private init() {
        self.aiService = AITranslationService.shared
        languageAdapters[.dog] = DogLanguageAdapter(aiService: aiService)
        languageAdapters[.cat] = CatLanguageAdapter()
        languageAdapters[.bird] = BirdLanguageAdapter()
    }

    func translate(input: String, language: AnimalLanguage, direction: MultiLanguageDirection) async throws -> MultiLanguageTranslationResult {
        guard let adapter = languageAdapters[language] else { throw MultiLanguageError.unsupportedLanguage }
        let start = Date()
        let result = try await adapter.translate(input: input, direction: direction)
        return MultiLanguageTranslationResult(
            translatedText: result.translation, sourceLanguage: direction.sourceLanguage,
            targetLanguage: direction.targetLanguage, qualityScore: result.qualityScore,
            inferenceTime: Date().timeIntervalSince(start), modelVersion: aiService.modelVersion,
            languageUsed: language
        )
    }

    func translateWithFallback(input: String, language: AnimalLanguage, direction: MultiLanguageDirection) -> String {
        if let pack = LanguagePackManager.shared.getPack(for: language) {
            let normalized = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if let translation = direction.sourceLanguage == nil ? pack.humanToAnimal[normalized] : pack.animalToHuman[normalized] {
                return translation
            }
        }
        return fallback(for: language)
    }

    private func fallback(for language: AnimalLanguage) -> String {
        switch language {
        case .dog: return "Woof!"
        case .cat: return "Meow!"
        case .bird: return "Chirp!"
        }
    }
}

enum MultiLanguageError: Error {
    case unsupportedLanguage
}

struct MultiLanguageTranslationResult {
    let translatedText: String
    let sourceLanguage: String?
    let targetLanguage: String?
    let qualityScore: Double
    let inferenceTime: TimeInterval
    let modelVersion: String
    let languageUsed: AnimalLanguage
}

enum MultiLanguageDirection {
    case humanToAnimal
    case animalToHuman

    var sourceLanguage: String? {
        switch self {
        case .humanToAnimal: return "human"
        case .animalToHuman: return nil
        }
    }

    var targetLanguage: String? {
        switch self {
        case .humanToAnimal: return nil
        case .animalToHuman: return "human"
        }
    }
}

protocol LanguageAdapterProtocol {
    func translate(input: String, direction: MultiLanguageDirection) async throws -> (translation: String, qualityScore: Double)
}

final class DogLanguageAdapter: LanguageAdapterProtocol {
    private let aiService: AITranslationService

    init(aiService: AITranslationService) {
        self.aiService = aiService
    }

    func translate(input: String, direction: MultiLanguageDirection) async throws -> (translation: String, qualityScore: Double) {
        let result = try await aiService.translate(input, from: "human", to: "dog")
        return (result.translatedText, result.confidence)
    }
}

final class CatLanguageAdapter: LanguageAdapterProtocol {
    func translate(input: String, direction: MultiLanguageDirection) async throws -> (translation: String, qualityScore: Double) {
        let mappings = ["hello": "meow", "goodbye": "mew", "yes": "purr", "no": "hiss"]
        return (mappings[input.lowercased()] ?? "meow", 0.6)
    }
}

final class BirdLanguageAdapter: LanguageAdapterProtocol {
    func translate(input: String, direction: MultiLanguageDirection) async throws -> (translation: String, qualityScore: Double) {
        let chirps = ["hello": "tweet tweet!", "goodbye": "chirp chirp...", "yes": "tweet!", "no": "squawk!"]
        return (chirps[input.lowercased()] ?? "chirp!", 0.5)
    }
}
