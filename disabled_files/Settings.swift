import Foundation
import SwiftUI

/// Manages user settings with persistence to UserDefaults
final class Settings {
    static let shared = Settings()
    
    private init() {
        // Load persisted values
        latencyThreshold = UserDefaults.standard.double(forKey: Keys.latencyThreshold)
        if latencyThreshold == 0 { latencyThreshold = 2.0 }
        
        audioQuality = AudioQuality(rawValue: UserDefaults.standard.integer(forKey: Keys.audioQuality)) ?? .medium
        enableVibration = UserDefaults.standard.bool(forKey: Keys.enableVibration)
        targetLanguage = UserDefaults.standard.string(forKey: Keys.targetLanguage) ?? "Dog"
    }
    
    // MARK: - Settings Properties
    
    /// Translation mode: AI, Rule-Based, or Auto
    var translationMode: TranslationMode {
        get { UserDefaults.standard.translationMode }
        set { UserDefaults.standard.translationMode = newValue }
    }
    
    /// Latency threshold in seconds
    var latencyThreshold: Double {
        didSet {
            UserDefaults.standard.set(latencyThreshold, forKey: Keys.latencyThreshold)
        }
    }
    
    /// Audio quality setting
    var audioQuality: AudioQuality {
        didSet {
            UserDefaults.standard.set(audioQuality.rawValue, forKey: Keys.audioQuality)
        }
    }
    
    /// Enable vibration feedback
    var enableVibration: Bool {
        didSet {
            UserDefaults.standard.set(enableVibration, forKey: Keys.enableVibration)
        }
    }
    
    /// Target language for translation
    var targetLanguage: String {
        didSet {
            UserDefaults.standard.set(targetLanguage, forKey: Keys.targetLanguage)
        }
    }
}

// MARK: - UserDefaults Keys

private enum Keys {
    static let latencyThreshold = "com.wooftalk.latencyThreshold"
    static let audioQuality = "com.wooftalk.audioQuality"
    static let enableVibration = "com.wooftalk.enableVibration"
    static let targetLanguage = "com.wooftalk.targetLanguage"
    // translationMode is already handled in AITranslationMetadata.swift UserDefaults extension
}

// MARK: - Audio Quality Enum

enum AudioQuality: Int {
    case low = 0
    case medium = 1
    case high = 2
}
