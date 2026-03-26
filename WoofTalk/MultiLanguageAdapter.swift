import Foundation
import CoreML

// MARK: - MultiLanguageAdapter

final class MultiLanguageAdapter {
    static let shared = MultiLanguageAdapter()
    
    private let aiService: AITranslationService
    private let packManager: LanguagePackManager
    private var languageAdapters: [AnimalLanguage: LanguageAdapterProtocol] = [:]
    private let adapterLock = NSLock()
    
    private init() {
        self.aiService = AITranslationService.shared
        self.packManager = LanguagePackManager.shared
        setupAdapters()
    }
    
    private func setupAdapters() {
        languageAdapters[.dog] = DogLanguageAdapter(aiService: aiService)
        languageAdapters[.cat] = CatLanguageAdapter()
        languageAdapters[.bird] = BirdLanguageAdapter()
    }
    
    func translate(
        input: String,
        language: AnimalLanguage,
        direction: MultiLanguageDirection
    ) async throws -> MultiLanguageTranslationResult {
        guard let adapter = languageAdapters[language] else {
            throw MultiLanguageError.unsupportedLanguage
        }
        
        let startTime = Date()
        
        do {
            let result = try await adapter.translate(input: input, direction: direction)
            let inferenceTime = Date().timeIntervalSince(startTime)
            
            return MultiLanguageTranslationResult(
                translatedText: result.translation,
                sourceLanguage: direction.sourceLanguage,
                targetLanguage: direction.targetLanguage,
                qualityScore: result.qualityScore,
                inferenceTime: inferenceTime,
                modelVersion: aiService.modelVersion,
                languageUsed: language
            )
        } catch {
            throw MultiLanguageError.translationFailed(error.localizedDescription)
        }
    }
    
    func translateWithFallback(
        input: String,
        language: AnimalLanguage,
        direction: MultiLanguageDirection
    ) -> String {
        if let pack = packManager.getPack(for: language) {
            let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            let dict = direction.sourceLanguage == nil 
                ? pack.humanToAnimal 
                : pack.animalToHuman
            
            if let translation = dict[normalizedInput] {
                return translation
            }
        }
        
        return fallbackSimpleTranslation(input: input, language: language, direction: direction)
    }
    
    private func fallbackSimpleTranslation(
        input: String,
        language: AnimalLanguage,
        direction: MultiLanguageDirection
    ) -> String {
        switch language {
        case .dog:
            return "Woof woof"
        case .cat:
            return "Meow"
        case .bird:
            return "Chirp"
        }
    }
    
    func isLanguageAvailable(_ language: AnimalLanguage) -> Bool {
        return languageAdapters[language] != nil
    }
    
    func getAdapter(for language: AnimalLanguage) -> LanguageAdapterProtocol? {
        return languageAdapters[language]
    }
}

// MARK: - LanguageAdapterProtocol

protocol LanguageAdapterProtocol {
    func translate(input: String, direction: MultiLanguageDirection) async throws -> LanguageAdapterResult
}

struct LanguageAdapterResult {
    let translation: String
    let confidence: Double
}

// MARK: - DogLanguageAdapter

final class DogLanguageAdapter: LanguageAdapterProtocol {
    private let aiService: AITranslationService
    
    init(aiService: AITranslationService) {
        self.aiService = aiService
    }
    
    func translate(input: String, direction: MultiLanguageDirection) async throws -> LanguageAdapterResult {
        let legacyDirection: TranslationDirection
        
        switch direction {
        case .humanToAnimal(.dog):
            legacyDirection = .humanToDog
        case .animalToHuman(.dog):
            legacyDirection = .dogToHuman
        default:
            throw MultiLanguageError.invalidDirection
        }
        
        let result = try await aiService.translate(input: input, direction: legacyDirection)
        
        return LanguageAdapterResult(
            translation: result.translatedText,
            confidence: result.qualityScore.confidence
        )
    }
}

// MARK: - CatLanguageAdapter

final class CatLanguageAdapter: LanguageAdapterProtocol {
    private let packManager = LanguagePackManager.shared
    
    func translate(input: String, direction: MultiLanguageDirection) async throws -> LanguageAdapterResult {
        guard let pack = packManager.getPack(for: .cat) else {
            throw MultiLanguageError.languagePackNotFound
        }
        
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let translation: String
        let confidence: Double
        
        switch direction {
        case .humanToAnimal(.cat):
            if let found = pack.humanToAnimal[normalizedInput] {
                translation = found
                confidence = 0.85
            } else {
                translation = translateToCat(input: input)
                confidence = 0.5
            }
        case .animalToHuman(.cat):
            if let found = pack.animalToHuman[normalizedInput] {
                translation = found
                confidence = 0.85
            } else {
                translation = translateFromCat(input: input)
                confidence = 0.5
            }
        default:
            throw MultiLanguageError.invalidDirection
        }
        
        return LanguageAdapterResult(translation: translation, confidence: confidence)
    }
    
    private func translateToCat(input: String) -> String {
        let lowerInput = input.lowercased()
        if lowerInput.contains("hello") || lowerInput.contains("hi") {
            return "Meow!"
        } else if lowerInput.contains("food") || lowerInput.contains("eat") {
            return "Meow meow!"
        } else if lowerInput.contains("play") {
            return "Chirp!"
        }
        return "Meow"
    }
    
    private func translateFromCat(input: String) -> String {
        let lowerInput = input.lowercased()
        if lowerInput.contains("meow") && !lowerInput.contains("meow meow") {
            return "Hello! I want attention!"
        } else if lowerInput.contains("purr") {
            return "I'm content and happy"
        } else if lowerInput.contains("hiss") {
            return "Stay away!"
        }
        return "Cat communication"
    }
}

// MARK: - BirdLanguageAdapter

final class BirdLanguageAdapter: LanguageAdapterProtocol {
    private let packManager = LanguagePackManager.shared
    
    func translate(input: String, direction: MultiLanguageDirection) async throws -> LanguageAdapterResult {
        guard let pack = packManager.getPack(for: .bird) else {
            throw MultiLanguageError.languagePackNotFound
        }
        
        let normalizedInput = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let translation: String
        let confidence: Double
        
        switch direction {
        case .humanToAnimal(.bird):
            if let found = pack.humanToAnimal[normalizedInput] {
                translation = found
                confidence = 0.85
            } else {
                translation = translateToBird(input: input)
                confidence = 0.5
            }
        case .animalToHuman(.bird):
            if let found = pack.animalToHuman[normalizedInput] {
                translation = found
                confidence = 0.85
            } else {
                translation = translateFromBird(input: input)
                confidence = 0.5
            }
        default:
            throw MultiLanguageError.invalidDirection
        }
        
        return LanguageAdapterResult(translation: translation, confidence: confidence)
    }
    
    private func translateToBird(input: String) -> String {
        let lowerInput = input.lowercased()
        if lowerInput.contains("hello") || lowerInput.contains("hi") {
            return "Chirp! Hello!"
        } else if lowerInput.contains("food") || lowerInput.contains("seed") {
            return "Chirp! Seeds please!"
        } else if lowerInput.contains("play") {
            return "Tweet tweet! Play time!"
        }
        return "Chirp"
    }
    
    private func translateFromBird(input: String) -> String {
        let lowerInput = input.lowercased()
        if lowerInput.contains("chirp chirp") {
            return "Hello! I'm here!"
        } else if lowerInput.contains("tweet tweet") {
            return "I'm happy!"
        } else if lowerInput.contains("sing") {
            return "I'm singing! Listen!"
        } else if lowerInput.contains("squawk") {
            return "Alert! Something wrong!"
        }
        return "Bird communication"
    }
}

// MARK: - MultiLanguageTranslationResult

struct MultiLanguageTranslationResult {
    let translatedText: String
    let sourceLanguage: AnimalLanguage?
    let targetLanguage: AnimalLanguage?
    let qualityScore: TranslationQualityScore
    let inferenceTime: TimeInterval
    let modelVersion: String
    let languageUsed: AnimalLanguage
    
    var isConfident: Bool {
        return qualityScore.confidence >= 0.5
    }
}

// MARK: - MultiLanguageError

enum MultiLanguageError: Error, LocalizedError {
    case unsupportedLanguage
    case invalidDirection
    case translationFailed(String)
    case languagePackNotFound
    case modelNotLoaded
    
    var errorDescription: String? {
        switch self {
        case .unsupportedLanguage:
            return "Language not supported"
        case .invalidDirection:
            return "Invalid translation direction"
        case .translationFailed(let reason):
            return "Translation failed: \(reason)"
        case .languagePackNotFound:
            return "Language pack not found"
        case .modelNotLoaded:
            return "Translation model not loaded"
        }
    }
}
