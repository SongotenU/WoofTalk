import Foundation

enum WatchTranslationDirection: String, Codable {
    case humanToDog = "humanToDog"
    case dogToHuman = "dogToHuman"
}

struct WatchTranslationResult {
    let translatedText: String
    let confidence: Double
}

final class WatchTranslationService {
    static let shared = WatchTranslationService()

    private let translations: [WatchTranslationDirection: [String: String]]

    private init() {
        translations = [
            .dogToHuman: [
                "woof woof": "Hello! I'm happy to see you!",
                "woof woof woof": "Let's go for a walk!",
                "woof woof woof woof": "I need to go outside!",
                "whine whine": "I'm worried or anxious",
                "bark bark": "Alert! Something is happening",
                "growl": "I'm warning you to stay back",
                "howl": "I'm calling for my pack / I miss you",
                "whimper": "I'm in pain or seeking attention",
                "yelp": "Ouch! That hurt!",
                "sniff sniff": "I'm investigating a scent"
            ],
            .humanToDog: [
                "hello": "Woof! Hello!",
                "good boy": "Tail wag! I'm a good boy!",
                "good girl": "Tail wag! I'm a good girl!",
                "sit": "I'll sit down",
                "stay": "I'll stay here",
                "come": "Coming to you!",
                "food": "Yum! Food time!",
                "walk": "Walk! Walk! Let's go!",
                "play": "Play time! Fetch!",
                "ball": "Ball! Throw the ball!",
                "treat": "Treat! I want a treat!",
                "outside": "Outside! I need to go out!",
                "no": "I understand, no",
                "yes": "Yes! I understand!"
            ]
        ]
    }

    func translate(input: String, direction: WatchTranslationDirection) -> WatchTranslationResult {
        let normalized = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let mapped = translations[direction]?[normalized] else {
            return WatchTranslationResult(translatedText: "Translation not available", confidence: 0.3)
        }
        return WatchTranslationResult(translatedText: mapped, confidence: 0.85)
    }

    var isModelAvailable: Bool { true }
}
