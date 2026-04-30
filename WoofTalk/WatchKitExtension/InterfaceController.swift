import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {

    @IBOutlet private weak var statusLabel: WKInterfaceLabel!
    @IBOutlet private weak var lastTranslationLabel: WKInterfaceLabel!

    private var session: WCSession?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        setupWatchSession()
        updateLastTranslation()
    }

    override func willActivate() {
        super.willActivate()
        updateLastTranslation()
    }

    private func setupWatchSession() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    private func updateLastTranslation() {
        if let last = WatchTranslationStore.shared.lastTranslation() {
            lastTranslationLabel.setText(last.translated)
        } else {
            lastTranslationLabel.setText("No translations yet")
        }

        let isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        if isPremium {
            statusLabel.setText("Premium: Active")
            statusLabel.setTextColor(.green)
        } else {
            statusLabel.setText("WoofTalk Ready")
            statusLabel.setTextColor(.yellow)
        }
    }

    @IBAction private func quickTranslateTapped() {
        let result = WatchTranslationService.shared.translate(
            input: "hello",
            direction: .humanToDog
        )
        lastTranslationLabel.setText(result.translatedText)
        HapticManager.shared.playForTranslation(result.translatedText)
        VoiceFeedbackManager.shared.speak(result.translatedText)

        let translation = WatchTranslation(
            input: "hello",
            translated: result.translatedText,
            direction: WatchTranslationDirection.humanToDog.rawValue
        )
        WatchTranslationStore.shared.save(translation)
        requestComplicationUpdate()
    }

    @IBAction private func openTranslatorTapped() {
        pushController(withName: "TranslationViewController", context: nil)
    }

    @IBAction private func openHistoryTapped() {
        pushController(withName: "HistoryInterfaceController", context: nil)
    }

    private func requestComplicationUpdate() {
        CLKComplicationServer.sharedInstance().activeComplications?.forEach {
            CLKComplicationServer.sharedInstance().reloadTimeline(for: $0)
        }
    }
}

extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error { print("[Watch] WCSession activation error: \(error)") }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let isPremium = applicationContext["isPremium"] as? Bool {
            UserDefaults.standard.set(isPremium, forKey: "isPremium")
        }
        if let tier = applicationContext["subscriptionTier"] as? String {
            UserDefaults.standard.set(tier, forKey: "subscriptionTier")
        }
        DispatchQueue.main.async {
            self.updateLastTranslation()
        }
    }
}
