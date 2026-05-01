import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {

    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("[Watch] WCSession activation error: \(error)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        // Sync subscription status from iPhone
        if let isPremium = applicationContext["isPremium"] as? Bool {
            UserDefaults.standard.set(isPremium, forKey: "isPremium")
        }
        if let tier = applicationContext["subscriptionTier"] as? String {
            UserDefaults.standard.set(tier, forKey: "subscriptionTier")
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        // Handle translation data from iPhone
        if let lastTranslation = userInfo["lastTranslation"] as? String {
            UserDefaults.standard.set(lastTranslation, forKey: "lastTranslation")
            // Reload complication
            CLKComplicationServer.sharedInstance().activeComplications?.forEach {
                CLKComplicationServer.sharedInstance().reloadTimeline(for: $0)
            }
        }
    }
}
