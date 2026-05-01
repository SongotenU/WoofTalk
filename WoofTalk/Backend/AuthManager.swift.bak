import Foundation
import Combine
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    private let supabase: SupabaseManager
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var platform: String = "ios"
    @Published var authErrorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let lastAuthKey = "lastAuthTimestamp"
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
                if let user {
                    self?.userDefaults.set(Date().timeIntervalSince1970, forKey: self?.lastAuthKey ?? "")
                    self?.userDefaults.set(self?.platform ?? "ios", forKey: self?.platformKey ?? "")
                }
            }
            .store(in: &cancellables)
    }
    
    func signIn(email: String, password: String) async {
        do {
            try await supabase.signIn(email: email, password: password)
            authErrorMessage = nil
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }
    
    func signUp(email: String, password: String) async {
        do {
            try await supabase.signUp(email: email, password: password, platform: platform)
            authErrorMessage = nil
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }
    
    func signOut() async {
        do {
            try await supabase.signOut()
            userDefaults.removeObject(forKey: lastAuthKey)
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }
    
    func refreshSessionIfNeeded() async {
        guard let session = supabase.supabaseClient.auth.currentSession else { return }
        let expiresAt = session.expiresAt
        let now = Date().timeIntervalSince1970
        if expiresAt - now < 300 {
            do {
                _ = try await supabase.supabaseClient.auth.refreshSession()
            } catch {
                authErrorMessage = "Session refresh failed: \(error.localizedDescription)"
            }
        }
    }
    
    var lastAuthDate: Date? {
        let timestamp = userDefaults.double(forKey: lastAuthKey)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
}

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String
    let avatarURL: String?
    let platform: String
    let isPremium: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case platform, isPremium = "is_premium"
    }
}
