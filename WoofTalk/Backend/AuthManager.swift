import Foundation
import Combine
import Supabase
import Security

// MARK: - Keychain Manager

/// Secure keychain storage for sensitive data
final class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    enum KeychainError: Error {
        case noData
        case unexpectedData
        case unhandledError(status: OSStatus)
    }
    
    func save(_ data: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func load(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }
        return data
    }
    
    func delete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func saveToken(_ token: String, key: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }
        try save(data, service: "com.wooftalk.app", account: key)
    }
    
    func loadToken(key: String) -> String? {
        guard let data = load(service: "com.wooftalk.app", account: key),
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }
    
    func deleteToken(key: String) throws {
        try delete(service: "com.wooftalk.app", account: key)
    }
    
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.wooftalk.app"
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}


@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    private let supabase: SupabaseManager
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var platform: String = "ios"
    @Published var authErrorMessage: String?
    
    // Non-sensitive data can use UserDefaults
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
                if let user {
                    // Store sensitive data in Keychain instead of UserDefaults
                    self?.storeSessionSecurely(user: user)
                } else {
                    self?.clearSession()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Secure Session Management
    
    private func storeSessionSecurely(user: User) {
        // Store non-sensitive data in UserDefaults
        userDefaults.set(platform, forKey: platformKey)
        userDefaults.set(Date().timeIntervalSince1970, forKey: "lastAuthTimestamp")
        
        // Store sensitive tokens in Keychain
        if let sessionToken = supabase.supabaseClient?.auth.currentSession?.accessToken {
            try? KeychainManager.shared.saveToken(sessionToken, key: "session_token")
        }
        if let refreshToken = supabase.supabaseClient?.auth.currentSession?.refreshToken {
            try? KeychainManager.shared.saveToken(refreshToken, key: "refresh_token")
        }
        try? KeychainManager.shared.saveToken(user.id, key: "user_id")
        try? KeychainManager.shared.saveToken(user.email, key: "user_email")
    }
    
    private func clearSession() {
        // Clear Keychain data
        try? KeychainManager.shared.deleteToken(key: "session_token")
        try? KeychainManager.shared.deleteToken(key: "refresh_token")
        try? KeychainManager.shared.deleteToken(key: "user_id")
        try? KeychainManager.shared.deleteToken(key: "user_email")
        
        // Clear non-sensitive UserDefaults
        userDefaults.removeObject(forKey: "lastAuthTimestamp")
    }
    
    func restoreSession() async {
        // Check if session exists in Keychain
        guard let sessionToken = KeychainManager.shared.loadToken(key: "session_token"),
              let userId = KeychainManager.shared.loadToken(key: "user_id") else {
            isAuthenticated = false
            return
        }
        
        // Validate token
        guard supabase.isTokenValid(sessionToken) else {
            clearSession()
            isAuthenticated = false
            return
        }
        
        // Attempt to restore user session
        do {
            let user = try await supabase.getUser(by: userId)
            currentUser = user
            isAuthenticated = true
        } catch {
            clearSession()
            isAuthenticated = false
        }
    }
    
    // MARK: - Authentication
    
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
        await supabase.signOut()
        clearSession()
        authErrorMessage = nil
    }
    
    // MARK: - Session Validation
    
    var lastAuthDate: Date? {
        let timestamp = userDefaults.double(forKey: "lastAuthTimestamp")
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    var isSessionExpired: Bool {
        guard let lastAuth = lastAuthDate else { return true }
        let sessionDuration: TimeInterval = 30 * 60 // 30 minutes
        return Date().timeIntervalSince(lastAuth) > sessionDuration
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
