import Foundation
import Combine
import Purchases

@MainActor
final class RevenueCatManager: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = RevenueCatManager()

    @Published var isConfigured = false
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
    }

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

    // MARK: - PurchasesDelegate

    nonisolated func purchases(_ purchases: Purchases, receivedCustomerInfo customerInfo: CustomerInfo) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .CustomerInfoUpdated,
                object: customerInfo
            )
        }
    }

    // MARK: - Public helpers

    func refreshCustomerInfo() async throws -> CustomerInfo {
        try await Purchases.shared.getCustomerInfo()
    }

    func logIn(userId: String) async throws {
        _ = try await Purchases.shared.logIn(userId)
    }
}

extension Notification.Name {
    static let CustomerInfoUpdated = Notification.Name("CustomerInfoUpdated")
}
