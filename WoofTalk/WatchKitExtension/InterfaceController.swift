import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    @IBOutlet weak var statusLabel: WKInterfaceLabel!

    private var session: WCSession?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    private func updateUI(isPremium: Bool, isTrialActive: Bool, tier: String) {
        if isPremium {
            statusLabel.setText("Premium: Active")
            statusLabel.setTextColor(.green)
        } else if isTrialActive {
            statusLabel.setText("Trial: \(tier)")
            statusLabel.setTextColor(.orange)
        } else {
            statusLabel.setText("Free Tier")
            statusLabel.setTextColor(.red)
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { print("[Watch] WCSession activation error: \(error)") }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let isPremium = applicationContext["isPremium"] as? Bool else { return }
        let isTrialActive = applicationContext["isTrialActive"] as? Bool ?? false
        let tier = applicationContext["subscriptionTier"] as? String ?? "free"
        DispatchQueue.main.async {
            self.updateUI(isPremium: isPremium, isTrialActive: isTrialActive, tier: tier)
        }
    }

    @IBAction func translateButtonTapped() {
        guard EntitlementManager.shared.isPremium else {
            print("Premium required for translation")
            return
        }
    }
}
