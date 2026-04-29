import Foundation
import Combine
import Supabase

final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var platform: String = "ios"

    private let supabase: SupabaseManager
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let platformKey = "userPlatform"

    private init(supabase: SupabaseManager = .shared) {
        self.supabase = supabase
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
}
