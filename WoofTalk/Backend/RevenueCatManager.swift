import Foundation
import Combine
import Purchases

@MainActor
final class RevenueCatManager: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = RevenueCatManager()

    @Published var isConfigured = false
    private var cancellables = Set<AnyCancellable>()

    private override init() { super.init() }

    func configure() {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_IOS_API_KEY") as? String ?? ""
        guard !apiKey.isEmpty else {
            print("[RevenueCat] REVENUECAT_IOS_API_KEY not set — SDK not initialized")
            return
        }
        Purchases.configure(withAPIKey: apiKey, appUserID: nil)
        Purchases.shared.delegate = self
        isConfigured = true
        observeAuthState()
    }

    private func observeAuthState() {
        AuthManager.shared.$isAuthenticated
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                guard let self else { return }
                if isAuthenticated, let userId = AuthManager.shared.currentUser?.id {
                    Task { try? await Purchases.shared.logIn(userId) }
                } else if !isAuthenticated {
                    Task { try? await Purchases.shared.logOut() }
                }
            }
            .store(in: &cancellables)
    }

    nonisolated func purchases(_ purchases: Purchases, receivedCustomerInfo customerInfo: CustomerInfo) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .CustomerInfoUpdated, object: customerInfo)
        }
    }

    func refreshCustomerInfo() async throws -> CustomerInfo { try await Purchases.shared.customerInfo() }
    func logIn(userId: String) async throws { _ = try await Purchases.shared.logIn(userId) }

    // MARK: - Promo Code Support
    func applyPromoCode(_ code: String) async throws -> CustomerInfo {
        // RevenueCat doesn't have direct promo code API in iOS SDK
        // Promo codes are typically handled via RevenueCat dashboard or Stripe
        // This method is a placeholder for future implementation
        return try await refreshCustomerInfo()
    }

    // MARK: - Subscription Pause/Resume
    // Note: Pause/resume is not directly supported in RevenueCat iOS SDK
    // These would need to be handled via RevenueCat API or Stripe

    // MARK: - Cancellation with Survey
    func cancelWithSurvey(reason: String, feedback: String?) async throws {
        // Update subscription_status in Supabase first
        if let userId = AuthManager.shared.currentUser?.id,
           let client = SupabaseManager.shared.client {
            let updateData: [String: Any] = [
                "cancellation_reason": reason,
                "cancellation_feedback": feedback ?? "",
                "cancelled_at": ISO8601DateFormatter().string(from: Date())
            ]
            try await client
                .from("subscription_status")
                .update(updateData)
                .eq("user_id", value: userId)
                .execute()
        }
        // Note: RevenueCat doesn't have a direct cancel method in the iOS SDK
        // Users typically cancel through App Store / Google Play settings
        // This is handled via the cancellation survey UI only
    }
}

extension Notification.Name {
    static let CustomerInfoUpdated = Notification.Name("CustomerInfoUpdated")
}
