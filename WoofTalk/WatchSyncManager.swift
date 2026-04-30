import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchSyncManager: NSObject, WCSessionDelegate {
    static let shared = WatchSyncManager()

    private var session: WCSession?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        activateSession()
        observeEntitlements()
    }

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    private func observeEntitlements() {
        let entitlement = EntitlementManager.shared

        Publishers.CombineLatest3(entitlement.$isPremium, entitlement.$isTrialActive, entitlement.$subscriptionTier)
            .removeDuplicates { $0 == $1 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium, isTrialActive, tier in
                self?.sendEntitlementContext(isPremium: isPremium, isTrialActive: isTrialActive, tier: tier)
            }
            .store(in: &cancellables)
    }

    private func sendEntitlementContext(isPremium: Bool, isTrialActive: Bool, tier: String) {
        guard let session, session.isPaired, session.isWatchAppInstalled else { return }
        let context: [String: Any] = [
            "isPremium": isPremium,
            "isTrialActive": isTrialActive,
            "subscriptionTier": tier
        ]
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("[WatchSync] Failed to update context: \(error)")
        }

        // Also send last translation if available
        if let lastTranslation = UserDefaults.standard.string(forKey: "lastTranslation") {
            let userInfo: [String: Any] = ["lastTranslation": lastTranslation]
            session.transferUserInfo(userInfo)
        }
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { print("[WatchSync] Activation error: \(error)") }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
