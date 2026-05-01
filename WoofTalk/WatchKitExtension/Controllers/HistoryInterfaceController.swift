import WatchKit
import Foundation

class HistoryInterfaceController: WKInterfaceController {
    @IBOutlet private weak var table: WKInterfaceTable!

    private var translations: [WatchTranslation] = []

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        loadTranslations()
    }

    override func willActivate() {
        super.willActivate()
        loadTranslations()
    }

    private func loadTranslations() {
        translations = WatchTranslationStore.shared.fetchAll()
        table.setNumberOfRows(translations.count, withRowType: "HistoryRow")

        for (index, translation) in translations.enumerated() {
            guard let row = table.rowController(at: index) as? HistoryRowController else { continue }
            let directionText = translation.direction == "humanToDog" ? "H→D" : "D→H"
            row.inputLabel.setText("\(directionText): \(translation.input)")
            row.translationLabel.setText(translation.translated)
        }
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        guard rowIndex < translations.count else { return }
        let translation = translations[rowIndex]
        let result = WatchTranslationService.shared.translate(input: translation.input, direction: translation.direction == "humanToDog" ? .humanToDog : .dogToHuman)
        VoiceFeedbackManager.shared.speak(result.translatedText)
        HapticManager.shared.play(.playful)
    }
}

class HistoryRowController: NSObject {
    @IBOutlet weak var inputLabel: WKInterfaceLabel!
    @IBOutlet weak var translationLabel: WKInterfaceLabel!
}
