import Foundation

/// Manages user settings with persistence to UserDefaults
final class Settings {
    static let shared = Settings()

    var translationMode: TranslationMode {
        get { UserDefaults.standard.translationMode }
        set { UserDefaults.standard.translationMode = newValue }
    }

    var latencyThreshold: Double {
        didSet { UserDefaults.standard.set(latencyThreshold, forKey: Keys.latencyThreshold) }
    }

    var audioQuality: AudioQuality {
        didSet { UserDefaults.standard.set(audioQuality.rawValue, forKey: Keys.audioQuality) }
    }

    var enableVibration: Bool {
        didSet { UserDefaults.standard.set(enableVibration, forKey: Keys.enableVibration) }
    }

    var targetLanguage: String {
        didSet { UserDefaults.standard.set(targetLanguage, forKey: Keys.targetLanguage) }
    }

    private init() {
        let defaults = UserDefaults.standard
        latencyThreshold = max(defaults.double(forKey: Keys.latencyThreshold), 2.0)
        audioQuality = AudioQuality(rawValue: defaults.integer(forKey: Keys.audioQuality)) ?? .medium
        enableVibration = defaults.bool(forKey: Keys.enableVibration)
        targetLanguage = defaults.string(forKey: Keys.targetLanguage) ?? "Dog"
    }
}

private enum Keys {
    static let latencyThreshold = "com.wooftalk.latencyThreshold"
    static let audioQuality = "com.wooftalk.audioQuality"
    static let enableVibration = "com.wooftalk.enableVibration"
    static let targetLanguage = "com.wooftalk.targetLanguage"
}

enum AudioQuality: Int {
    case low = 0, medium = 1, high = 2
}
