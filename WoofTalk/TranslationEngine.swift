import Foundation

/// Bidirectional translation engine: bark -> human text and human text -> bark.
class TranslationEngine {

    // MARK: - Bark to Human

    struct BarkPattern {
        static let patterns: [String: String] = [
            "single_short_bark": "I'm here! / Hey!",
            "double_bark": "I want attention! / Play with me!",
            "repeated_excited": "I'm so happy to see you! 😊",
            "deep_slow_bark": "Someone's nearby! / Watch out!",
            "whine": "I'm scared or want something...",
            "growl": "Back off! I'm uncomfortable.",
            "howl": "I'm lonely! / Where are you?",
            "yap_yap_yap": "I'm anxious or excited about something!",
            "pant_whine": "I'm tired and want to rest",
            "play_bow_bark": "Let's play! I'm friendly!"
        ]

        /// Analyze audio characteristics to detect bark pattern
        static func detectPattern(audioLevel: Float, duration: TimeInterval, barkCount: Int) -> String? {
            // Simple detection based on duration and intensity heuristics
            let intensity = audioLevel

            if intensity < 0.15 {
                return nil // ambient noise, not a bark
            }

            if duration < 0.2 {
                return patterns["single_short_bark"]
            } else if duration < 0.5 {
                return patterns["single_short_bark"]
            } else if duration < 1.0 && intensity < 0.5 {
                return patterns["whine"]
            } else if duration < 1.0 && intensity >= 0.5 {
                return patterns["single_short_bark"]
            } else if duration < 2.0 && intensity < 0.4 {
                return patterns["growl"]
            } else if duration < 2.0 && intensity >= 0.4 {
                return barkCount <= 2 ? patterns["double_bark"] : patterns["repeated_excited"]
            } else if duration < 4.0 {
                return intensity > 0.6 ? patterns["howl"] : patterns["pant_whine"]
            } else {
                return intensity > 0.5 ? patterns["howl"] : patterns["pant_whine"]
            }
        }
    }

    // MARK: - Human to Bark

    struct HumanToBark {
        static let translations: [String: String] = [
            "hello": "Woof!",
            "good boy": "Arf arf! *wag wag*",
            "sit": "Woof? *tilts head*",
            "stay": "Bark! *waits patiently*",
            "come here": "Woof woof! *runs over excitedly*",
            "good dog": "*happy panting* Arf!",
            "walk": "WOOF WOOF WOOF! *spins in circles*",
            "food": "*drooling* Bark! Bark!",
            "love you": "*gentle whine* *snuggles closer*",
            "bedtime": "*yawn* *curls up* soft woof",
            "treat": "WOOF! *does tricks* Bark!",
            "outside": "Arf arf! *scratches door*",
            "no": "*ears down* whimper",
            "who's a good boy": "*tail goes crazy* WOOF! WOOF!"
        ]

        static func translate(_ text: String) -> String {
            let lowercased = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            if let translation = translations[lowercased] {
                return translation
            }

            // Check partial matches
            for (key, value) in translations {
                if lowercased.contains(key) || key.contains(lowercased) {
                    return value
                }
            }

            // Default: generate a generic happy response
            let count = Int.random(in: 1...3)
            let woofs = Array(repeating: "Woof", count: count).joined(separator: " ")
            return "\(woofs)! *happy dog sounds*"
        }
    }

    // MARK: - State

    private var barkSessionStart: Date?
    private var detectedBarkCount = 0
    var lastBarkTranslation: String?

    /// Called when audio level indicates a bark event.
    /// Returns the translated text if a bark was detected.
    func processBark(audioLevel: Float, duration: TimeInterval) -> String? {
        if audioLevel < 0.15 {
            return nil
        }

        detectedBarkCount += 1
        let translation = BarkPattern.detectPattern(
            audioLevel: audioLevel,
            duration: duration,
            barkCount: detectedBarkCount
        )
        lastBarkTranslation = translation
        return translation
    }

    /// Translate human text to bark response.
    func humanToBark(_ text: String) -> String {
        detectedBarkCount = 0
        return HumanToBark.translate(text)
    }

    func reset() {
        detectedBarkCount = 0
        barkSessionStart = nil
        lastBarkTranslation = nil
    }
}
