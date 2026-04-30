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
        // Listen for CustomerInfo updates from RevenueCat
        Purchases.shared.customerInfo { [weak self] (customerInfo, error) in
            if let error = error {
                print("[EntitlementManager] Failed to get initial customer info: \(error)")
                return
            }
            if let customerInfo = customerInfo {
                self?.update(from: customerInfo)
            }
        }

        // Listen for ongoing CustomerInfo updates
        NotificationCenter.default.publisher(for: .RCUpdatedCustomerInfo)
            .compactMap { $0.object as? CustomerInfo }
            .sink { [weak self] in self?.update(from: $0) }
            .store(in: &cancellables)
    }

    private func update(from customerInfo: CustomerInfo) {
        let isProActive = customerInfo.entitlements["pro"]?.isActive == true
        let isTrialActive = customerInfo.entitlements["trial"]?.isActive == true

        isPremium = isProActive
        self.isTrialActive = isTrialActive
        subscriptionTier = isProActive ? "pro" : (isTrialActive ? "trial" : "free")
    }

    func refreshEntitlements() async {
        isLoading = true
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            update(from: customerInfo)
        } catch {
            self.error = error
            print("[EntitlementManager] Failed to refresh entitlements: \(error)")
        }
        isLoading = false
    }

    func checkEntitlements() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                update(from: customerInfo)
            } catch {
                print("[EntitlementManager] Failed to check entitlements: \(error)")
            }
        }
    }

    func logIn(appUserId: String) async throws {
        let (customerInfo, _) = try await Purchases.shared.logIn(appUserId)
        update(from: customerInfo)
    }

    func logOut() async throws {
        let customerInfo = try await Purchases.shared.logOut()
        update(from: customerInfo)
    }
}
