import WatchKit
import Foundation
import AVFoundation

class TranslationViewController: WKInterfaceController {
    @IBOutlet private weak var inputLabel: WKInterfaceLabel!
    @IBOutlet private weak var translationLabel: WKInterfaceLabel!
    @IBOutlet private weak var statusLabel: WKInterfaceLabel!

    private var currentDirection: WatchTranslationDirection = .humanToDog
    private var currentInput: String = ""
    private var isSpeaking = false

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        updateUIForDirection()
    }

    private func updateUIForDirection() {
        let directionText = currentDirection == .humanToDog ? "Human → Dog" : "Dog → Human"
        statusLabel.setText(directionText)
        inputLabel.setText("Tap to speak")
        translationLabel.setText("")
    }

    @IBAction private func switchDirectionTapped() {
        currentDirection = currentDirection == .humanToDog ? .dogToHuman : .humanToDog
        updateUIForDirection()
        HapticManager.shared.play(.click)
    }

    @IBAction private func translateTapped() {
        // Simulate voice input for Watch - in production this would use Watch speech recognition
        let sampleInputs: [WatchTranslationDirection: [String]] = [
            .humanToDog: ["hello", "good boy", "walk", "play", "treat"],
            .dogToHuman: ["woof woof", "woof woof woof", "bark bark", "whine whine", "growl"]
        ]
        guard let inputs = sampleInputs[currentDirection] else { return }
        let input = inputs.randomElement() ?? "hello"
        currentInput = input
        inputLabel.setText(input)

        let result = WatchTranslationService.shared.translate(input: input, direction: currentDirection)
        translationLabel.setText(result.translatedText)

        // Haptic feedback based on translation
        HapticManager.shared.playForTranslation(result.translatedText)

        // Voice feedback
        VoiceFeedbackManager.shared.speak(result.translatedText)

        // Save translation locally
        let watchTranslation = WatchTranslation(
            input: input,
            translated: result.translatedText,
            direction: currentDirection.rawValue
        )
        WatchTranslationStore.shared.save(watchTranslation)

        // Update complication if available
        updateComplication()
    }

    @IBAction private func replayVoiceTapped() {
        guard !currentInput.isEmpty else { return }
        let result = WatchTranslationService.shared.translate(input: currentInput, direction: currentDirection)
        VoiceFeedbackManager.shared.speak(result.translatedText)
    }

    private func updateComplication() {
        // Request complication update
        if let newData = WatchTranslationStore.shared.lastTranslation() {
            let context: [String: Any] = [
                "lastTranslation": newData.translated,
                "timestamp": newData.timestamp.timeIntervalSince1970
            ]
            WCSession.default.transferUserInfo(context)
        }
    }

    @IBAction private func viewHistoryTapped() {
        pushController(withName: "HistoryInterfaceController", context: nil)
    }
}
