final class LanguageRoutingService {
    static let shared = LanguageRoutingService()

    private let multiLanguageAdapter = MultiLanguageAdapter.shared
    private let storageManager = LanguageStorageManager.shared

    var currentLanguage: AnimalLanguage {
        get { storageManager.selectedLanguage }
        set { storageManager.selectedLanguage = newValue }
    }

    var isAutoDetectionEnabled: Bool {
        get { storageManager.isAutoDetectionEnabled }
        set { storageManager.isAutoDetectionEnabled = newValue }
    }

    func translate(
        input: String,
        direction: MultiLanguageDirection,
        overrideLanguage: AnimalLanguage? = nil
    ) async throws -> MultiLanguageTranslationResult {
        let language = overrideLanguage ?? (isAutoDetectionEnabled ? direction.sourceLanguage : nil) ?? currentLanguage
        return try await multiLanguageAdapter.translate(input: input, language: language, direction: direction)
    }

    func translateWithFallback(
        input: String,
        direction: MultiLanguageDirection,
        overrideLanguage: AnimalLanguage? = nil
    ) -> String {
        multiLanguageAdapter.translateWithFallback(input: input, language: overrideLanguage ?? currentLanguage, direction: direction)
    }

    func getAvailableLanguages() -> [LanguageMetadata] {
        AnimalLanguage.allCases.map { language in
            language.metadata(vocabularySize: LanguagePackManager.shared.vocabularySize(for: language))
        }
    }

    func isLanguageSupported(_ language: AnimalLanguage) -> Bool {
        multiLanguageAdapter.isLanguageAvailable(language)
    }
}

final class LanguageStorageManager {
    static let shared = LanguageStorageManager()

    private let defaults = UserDefaults.standard

    private let selectedLanguageKey = "selectedAnimalLanguage"
    private let autoDetectionKey = "autoDetectionEnabled"
    private let recentLanguagesKey = "recentLanguages"

    var selectedLanguage: AnimalLanguage {
        get {
            defaults.string(forKey: selectedLanguageKey).flatMap(AnimalLanguage.init) ?? .dog
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
            (defaults.stringArray(forKey: recentLanguagesKey) ?? []).compactMap(AnimalLanguage.init)
        }
        set {
            defaults.set(newValue.prefix(5).map { $0.rawValue }, forKey: recentLanguagesKey)
        }
    }

    init() {
        defaults.register(defaults: [
            selectedLanguageKey: AnimalLanguage.dog.rawValue,
            autoDetectionKey: false
        ])
    }

    private func addToRecent(_ language: AnimalLanguage) {
        var recent = recentLanguages
        recent.removeAll { $0 == language }
        recent.insert(language, at: 0)
        if recent.count > 5 { recent = Array(recent.prefix(5)) }
        recentLanguages = recent
    }

    func reset() {
        defaults.removeObject(forKey: selectedLanguageKey)
        defaults.removeObject(forKey: autoDetectionKey)
        defaults.removeObject(forKey: recentLanguagesKey)
    }
}
