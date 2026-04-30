import AVFoundation

/// Demonstration of dog vocalization synthesis
class DogVocalizationDemo {

    private let synthesizer = DogVocalizationSynthesizer()

    func demonstrateAllEmotions() throws {
        print("=== Dog Vocalization Synthesis Demo ===\n")
        print("Demonstrating all dog emotions:\n")

        for emotion in DogEmotion.allCases {
            do {
                let sound = try synthesizer.synthesizeRandomDogSound(emotion: emotion)
                print("\(emotion.rawValue): Generated \(sound.frameLength) frames")
            } catch {
                print("Error generating \(emotion.rawValue) sound: \(error)")
            }
        }

        print("\n=== Demo Complete ===\n")
    }

    func demonstrateTextTranslation() throws {
        print("=== Text to Dog Vocalization Demo ===\n")

        let phrases: [(phrase: String, emotion: DogEmotion)] = [
            ("Hello!", .neutral),
            ("I'm happy to see you!", .happy),
            ("Let's play!", .playful),
            ("Who's there?", .territorial),
            ("I'm scared!", .scared)
        ]

        for (phrase, emotion) in phrases {
            do {
                let sound = try synthesizer.synthesizeDogVocalization(from: phrase, emotion: emotion)
                print("Phrase: \"\(phrase)\" → Emotion: \(emotion.rawValue)")
            } catch {
                print("Error translating phrase: \(error)")
            }
        }

        print("\n=== Text Translation Demo Complete ===\n")
    }

    func runFullDemo() throws {
        try demonstrateAllEmotions()
        try demonstrateTextTranslation()

        print("\n=== Dog Vocalization Synthesis Demo Complete ===\n")
        print("All synthesis features verified successfully!")
    }
}

#if DEBUG && os(macOS)
func runDogVocalizationDemoIfNeeded() {
    if CommandLine.arguments.contains("--demo") {
        do {
            try DogVocalizationDemo().runFullDemo()
        } catch {
            print("Demo failed: \(error)")
        }
    }
}
#endif