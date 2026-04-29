import Foundation
import Combine

// MARK: - Simulator build mocks (RevenueCat not linked)

struct CustomerInfo {
    let entitlements: [String: Entitlement]
    let activeSubscriptions: Set<String>

    struct Entitlement { let isActive: Bool }
}

extension Notification.Name {
    static let CustomerInfoUpdated = Notification.Name("CustomerInfoUpdated")
}

final class Purchases {
    static let shared = Purchases()
    func getCustomerInfo() async throws -> CustomerInfo {
        CustomerInfo(entitlements: [:], activeSubscriptions: [])
    }
    func restorePurchases() async throws -> CustomerInfo {
        CustomerInfo(entitlements: [:], activeSubscriptions: [])
    }
}

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
        NotificationCenter.default.publisher(for: .CustomerInfoUpdated)
            .compactMap { $0.object as? CustomerInfo }
            .sink { [weak self] in self?.update(from: $0) }
            .store(in: &cancellables)
    }

    private func update(from customerInfo: CustomerInfo) {
        let isActive = customerInfo.entitlements["pro"]?.isActive == true
        isPremium = isActive
        subscriptionTier = isActive ? (customerInfo.activeSubscriptions.isEmpty ? "trial" : "pro") : "free"
    }

    func refreshEntitlements() async {
        isLoading = true
        do {
            update(from: try await Purchases.shared.getCustomerInfo())
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func checkEntitlements() {
        Task {
            if let info = try? await Purchases.shared.getCustomerInfo() {
                update(from: info)
            }
        }
    }
}
