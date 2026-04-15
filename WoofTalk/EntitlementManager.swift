import Foundation
import Combine
import Purchases

@MainActor
final class EntitlementManager: ObservableObject {
    static let shared = EntitlementManager()

    @Published var isPremium: Bool = false
    @Published var isTrialActive: Bool = false
    @Published var dailyTranslationsUsed: Int = 0
    @Published var subscriptionTier: String = "free"
    @Published var isLoading: Bool = false
    @Published var error: Error?

    var isReadyToAccessPaywall: Bool {
        return AuthManager.shared.isAuthenticated
    }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        NotificationCenter.default.publisher(for: .CustomerInfoUpdated)
            .receive(on: DispatchQueue.main)
            .compactMap { $0.object as? CustomerInfo }
            .sink { [weak self] customerInfo in
                self?.updateFromCustomerInfo(customerInfo)
            }
            .store(in: &cancellables)
    }

    private func updateFromCustomerInfo(_ customerInfo: CustomerInfo) {
        let proEntitlement = customerInfo.entitlements["pro"]
        let isPremiumActive = proEntitlement?.isActive == true
        isPremium = isPremiumActive

        // Detect trial: active entitlement but no active paid subscriptions
        let isTrial = isPremiumActive && customerInfo.activeSubscriptions.isEmpty
        isTrialActive = isTrial

        subscriptionTier = {
            if isPremiumActive && !isTrial { return "pro" }
            if isPremiumActive && isTrial { return "trial" }
            return "free"
        }()
    }

    func refreshEntitlements() async {
        isLoading = true
        do {
            let customerInfo = try await RevenueCatManager.shared.refreshCustomerInfo()
            updateFromCustomerInfo(customerInfo)
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func checkEntitlements() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.getCustomerInfo()
                updateFromCustomerInfo(customerInfo)
            } catch {
                // D-05: Trust cached CustomerInfo when offline
            }
        }
    }
}
