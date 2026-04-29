import Foundation
import Combine
import Supabase
import CoreData

final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var platform: String = "ios"

    private let supabase: SupabaseManager
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let platformKey = "userPlatform"
    private let coreDataContext: NSManagedObjectContext

    private init(supabase: SupabaseManager = .shared) {
        self.supabase = supabase
        self.coreDataContext = PersistenceController.shared.container.viewContext
        self.platform = userDefaults.string(forKey: platformKey) ?? "ios"
        observeAuthState()
    }

    private func observeAuthState() {
        supabase.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthenticated)

        supabase.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                if let user = user {
                    self?.storeSessionSecurely(user: user)
                } else {
                    self?.clearSession()
                }
            }
            .store(in: &cancellables)
    }

    func signUp(email: String, password: String) async throws -> User {
        try await supabase.signUp(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws -> User {
        try await supabase.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await supabase.signOut()
        clearSession()
    }

    func updatePlatform(_ newPlatform: String) {
        platform = newPlatform
        userDefaults.set(newPlatform, forKey: platformKey)
    }

    private func storeSessionSecurely(user: User) {
        userDefaults.set(Date().timeIntervalSince1970, forKey: "lastAuthTimestamp")
    }

    private func clearSession() {
        userDefaults.removeObject(forKey: "lastAuthTimestamp")
    }

    func signInWithGitHub() async throws -> User {
        throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "GitHub auth not yet implemented"])
    }

    func handleGitHubCallback(url: URL) async throws -> User {
        throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "GitHub callback handling not yet implemented"])
    }

    func exportUserData() async throws -> [String: Any] {
        guard let user = currentUser else { throw NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]) }
        var userData: [String: Any] = [
            "userId": user.id?.uuidString ?? "",
            "email": user.email ?? "",
            "platform": platform,
            "exportDate": Date().timeIntervalSince1970
        ]
        do {
            let translations = try await supabase.fetchTranslations(limit: 1000)
            userData["translations"] = translations.map { $0.humanText }
        } catch { userData["translationsError"] = error.localizedDescription }
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        if let userId = user.id?.uuidString { fetchRequest.predicate = NSPredicate(format: "submitterId == %@", userId) }
        if let contributions = try? coreDataContext.fetch(fetchRequest) {
            userData["contributions"] = contributions.count
        }
        return userData
    }

    func deleteAccount() async throws {
        try await supabase.signOut()
        clearSession()
    }

    func updateDeviceToken(_ token: String) {
        userDefaults.set(token, forKey: "deviceToken")
        // Send to Supabase for push notifications
        Task {
            do {
                guard let userId = currentUser?.id?.uuidString else { return }
                try await supabase.client?
                    .from("user_push_tokens")
                    .upsert(["user_id": userId, "token": token, "platform": "ios", "updated_at": ISO8601DateFormatter().string(from: Date())])
                    .execute()
            } catch {
                print("Failed to update device token: \(error)")
            }
        }
    }
}
