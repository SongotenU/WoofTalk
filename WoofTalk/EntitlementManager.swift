import Foundation
import RevenueCat
import Combine

@MainActor
final class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()

    @Published var isPremium = false
    @Published var isTrialActive = false
    @Published var subscriptionTier = "free"
    @Published var isLoading = false
    @Published var error: Error?

    var isReadyToAccessPaywall: Bool { AuthManager.shared.isAuthenticated }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Initial fetch using async/await pattern (v5.x)
        Task {
            await refreshEntitlements()
        }

        // Listen for ongoing CustomerInfo updates using notification (v5.x compatible)
        NotificationCenter.default.publisher(for: .RCUpdatedCustomerInfo)
            .compactMap { $0.object as? CustomerInfo }
            .sink { [weak self] in self?.update(from: $0) }
            .store(in: &cancellables)
    }

    private func update(from customerInfo: CustomerInfo) {
        let isProActive = customerInfo.entitlements.all["pro"]?.isActive == true
        let isPremiumEntActive = customerInfo.entitlements.all["premium"]?.isActive == true
        let isTrialActive = customerInfo.entitlements.all["premium"]?.isInIntroOfferPeriod == true

        isPremium = isProActive || isPremiumEntActive
        self.isTrialActive = isTrialActive
        subscriptionTier = isProActive ? "pro" : (isPremiumEntActive || isTrialActive ? "premium" : "free")
    }

    func refreshEntitlements() async {
        await MainActor.run { isLoading = true }
        do {
            // v5.x uses getCustomerInfo() instead of customerInfo(completion:)
            let customerInfo = try await RevenueCat.Purchases.shared.getCustomerInfo()
            await update(from: customerInfo)
        } catch {
            await MainActor.run {
                self.error = error
                print("[EntitlementManager] Failed to refresh entitlements: \(error)")
            }
        }
        await MainActor.run { isLoading = false }
    }

    func checkEntitlements() {
        Task {
            do {
                let customerInfo = try await RevenueCat.Purchases.shared.getCustomerInfo()
                await update(from: customerInfo)
            } catch {
                print("[EntitlementManager] Failed to check entitlements: \(error)")
            }
        }
    }

    func logIn(appUserId: String) async throws {
        // v5.x API - logIn returns CustomerInfo directly
        let customerInfo = try await RevenueCat.Purchases.shared.logIn(appUserId)
        await update(from: customerInfo)
    }

    func logOut() async throws {
        // v5.x API - logOut returns CustomerInfo directly
        let customerInfo = try await RevenueCat.Purchases.shared.logOut()
        await update(from: customerInfo)
    }

    /// Get current customer info
    /// - Returns: Current CustomerInfo
    func getCustomerInfo() async throws -> CustomerInfo {
        try await RevenueCat.Purchases.shared.getCustomerInfo()
    }
}