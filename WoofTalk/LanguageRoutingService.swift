import Foundation

// MARK: - LanguageRoutingService

final class LanguageRoutingService {
    static let shared = LanguageRoutingService()
    
    private let multiLanguageAdapter: MultiLanguageAdapter
    private let detectionManager: LanguageDetectionManager
    private let storageManager: LanguageStorageManager
    
    var currentLanguage: AnimalLanguage {
        get { storageManager.selectedLanguage }
        set { storageManager.selectedLanguage = newValue }
    }
    
    var isAutoDetectionEnabled: Bool {
        get { storageManager.isAutoDetectionEnabled }
        set { storageManager.isAutoDetectionEnabled = newValue }
    }
    
    private init() {
        self.multiLanguageAdapter = MultiLanguageAdapter.shared
        self.detectionManager = LanguageDetectionManager.shared
        self.storageManager = LanguageStorageManager.shared
    }
    
    func translate(
        input: String,
        direction: MultiLanguageDirection,
        overrideLanguage: AnimalLanguage? = nil
    ) async throws -> MultiLanguageTranslationResult {
        let language = overrideLanguage ?? determineLanguage(for: direction)
        
        let result = try await multiLanguageAdapter.translate(
            input: input,
            language: language,
            direction: direction
        )
        
        return result
    }
    
    func translateWithFallback(
        input: String,
        direction: MultiLanguageDirection,
        overrideLanguage: AnimalLanguage? = nil
    ) -> String {
        let language = overrideLanguage ?? currentLanguage
        
        return multiLanguageAdapter.translateWithFallback(
            input: input,
            language: language,
            direction: direction
        )
    }
    
    private func determineLanguage(for direction: MultiLanguageDirection) -> AnimalLanguage {
        if isAutoDetectionEnabled {
            if let detectedLanguage = direction.sourceLanguage {
                return detectedLanguage
            }
        }
        
        return currentLanguage
    }
    
    func setLanguage(_ language: AnimalLanguage) {
        currentLanguage = language
    }
    
    func getAvailableLanguages() -> [LanguageMetadata] {
        return AnimalLanguage.allCases.map { language in
            let vocabularySize = LanguagePackManager.shared.vocabularySize(for: language)
            return language.metadata(vocabularySize: vocabularySize)
        }
    }
    
    func isLanguageSupported(_ language: AnimalLanguage) -> Bool {
        return multiLanguageAdapter.isLanguageAvailable(language)
    }
}

// MARK: - LanguageStorageManager

final class LanguageStorageManager {
    static let shared = LanguageStorageManager()
    
    private let defaults = UserDefaults.standard
    
    private let selectedLanguageKey = "selectedAnimalLanguage"
    private let autoDetectionKey = "autoDetectionEnabled"
    private let recentLanguagesKey = "recentLanguages"
    
    var selectedLanguage: AnimalLanguage {
        get {
            guard let rawValue = defaults.string(forKey: selectedLanguageKey),
                  let language = AnimalLanguage(rawValue: rawValue) else {
                return .dog
            }
            return language
        }
        set {
            defaults.set(newValue.rawValue, forKey: selectedLanguageKey)
            addToRecent(newValue)
        }
    }
    
    var isAutoDetectionEnabled: Bool {
        get { defaults.bool(forKey: autoDetectionKey) }
        set { defaults.set(newValue, forKey: autoDetectionKey) }
    }
    
    var recentLanguages: [AnimalLanguage] {
        get {
            guard let rawValues = defaults.stringArray(forKey: recentLanguagesKey) else {
                return []
            }
            return rawValues.compactMap { AnimalLanguage(rawValue: $0) }
        }
        set {
            let rawValues = newValue.prefix(5).map { $0.rawValue }
            defaults.set(Array(rawValues), forKey: recentLanguagesKey)
        }
    }
    
    private init() {
        registerDefaults()
    }
    
    private func registerDefaults() {
        defaults.register(defaults: [
            selectedLanguageKey: AnimalLanguage.dog.rawValue,
            autoDetectionKey: false
        ])
    }
    
    private func addToRecent(_ language: AnimalLanguage) {
        var recent = recentLanguages
        recent.removeAll { $0 == language }
        recent.insert(language, at: 0)
        recentLanguages = Array(recent.prefix(5))
    }
    
    func reset() {
        defaults.removeObject(forKey: selectedLanguageKey)
        defaults.removeObject(forKey: autoDetectionKey)
        defaults.removeObject(forKey: recentLanguagesKey)
    }
}
