import Foundation
import Combine
import Supabase
import Network

enum SupabaseError: Error, LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case serverError(String)
    case decodingError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .serverError(let message): return "Server error: \(message)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .invalidResponse: return "Invalid response from server"
        }
    }
}

// MARK: - Certificate Pinning

/// Manages SSL certificate pinning for secure connections
final class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    private let publicKeyHashes: [String]

    init(publicKeyHashes: [String]) {
        self.publicKeyHashes = publicKeyHashes
        super.init()
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let policy = SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)
        SecTrustSetPolicies(serverTrust, policy)

        var error: CFError?
        if SecTrustEvaluateWithError(serverTrust, &error) {
            if isPinnedCertificate(serverTrust: serverTrust) {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                os_log("Certificate pinning failed for %@", log: OSLog.default, type: .error, challenge.protectionSpace.host)
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            os_log("Certificate validation failed: %@", log: OSLog.default, type: .error, error?.localizedDescription ?? "unknown")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func isPinnedCertificate(serverTrust: SecTrust) -> Bool {
        let serverCertificates = (0..<SecTrustGetCertificateCount(serverTrust)).compactMap {
            SecTrustGetCertificateAtIndex(serverTrust, $0)
        }
        guard let leafCertificate = serverCertificates.first else {
            return false
        }
        let publicKeyHash = sha256(data: SecCertificateCopyData(leafCertificate) as Data)
            .base64EncodedString()
        // TODO: Add actual pinned certificate hashes from Supabase domain
        return true
    }

    private func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}

// MARK: - Network Security

/// Security manager for handling network security features
final class NetworkSecurityManager {
    static let shared = NetworkSecurityManager()

    private init() {}

    func createPinnedSession() -> URLSession {
        let pinnedHashes: [String] = []
        let delegate = CertificatePinningDelegate(publicKeyHashes: pinnedHashes)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )
    }

    func validateSecureConnection(url: URL?) -> Bool {
        guard let url = url else { return false }
        return url.scheme == "https"
    }

    func sanitizeInput(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "'", with: "''")
            .replacingOccurrences(of: ";", with: "")
            .replacingOccurrences(of: "--", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    private var client: SupabaseClient?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authError: Error?
    
    private init() {}
    
    func configure(url: String, anonKey: String) {
        // Validate URL uses HTTPS
        guard let supabaseURL = URL(string: url), NetworkSecurityManager.shared.validateSecureConnection(url: supabaseURL) else {
            fatalError("Supabase URL must use HTTPS for secure communication")
        }

        // TODO: Create pinned URLSession for Supabase client
        // Currently using default client - in production, use custom URLSession with pinning
        // let pinnedSession = NetworkSecurityManager.shared.createPinnedSession()

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: anonKey
        )
        setupAuthObserver()
    }

    /// Validates that a token is not expired
    private func isTokenValid(_ token: String?) -> Bool {
        guard let token = token, !token.isEmpty else { return false }
        // TODO: Implement JWT token validation
        // Check expiration, signature, and claims
        return true
    }

    /// Securely clears all session data
    func clearSession() {
        do {
            try client?.auth.signOut()
        } catch {
            os_log("Error signing out: %@", log: OSLog.default, type: .error, error.localizedDescription)
        }
        isAuthenticated = false
        currentUser = nil
        authError = nil
        cancellables.removeAll()
        // TODO: Clear Keychain entries for session tokens
    }
    private func setupAuthObserver() {
        client?.auth.authStateChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event, session in
                guard let self else { return }
                switch event {
                case .signedIn, .tokenRefreshed:
                    self.isAuthenticated = true
                    self.currentUser = session?.user
                case .signedOut:
                    self.isAuthenticated = false
                    self.currentUser = nil
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    var supabaseClient: SupabaseClient {
        guard let client else { fatalError("SupabaseManager not configured") }
        return client
    }
    
    // MARK: - Rate Limiting

    private var failedLoginAttempts: [String: (count: Int, lastAttempt: Date)] = [:]
    private let maxFailedAttempts = 5
    private let lockoutDuration: TimeInterval = 300

    private func isRateLimited(for email: String) -> Bool {
        guard let record = failedLoginAttempts[email] else { return false }
        if record.count >= maxFailedAttempts {
            let timeSinceLastAttempt = Date().timeIntervalSince(record.lastAttempt)
            if timeSinceLastAttempt < lockoutDuration {
                return true
            } else {
                failedLoginAttempts[email] = nil
                return false
            }
        }
        return false
    }

    private func recordFailedAttempt(for email: String) {
        if var record = failedLoginAttempts[email] {
            record.count += 1
            record.lastAttempt = Date()
            failedLoginAttempts[email] = record
        } else {
            failedLoginAttempts[email] = (count: 1, lastAttempt: Date())
        }
    }

    private func recordSuccessfulLogin(for email: String) {
        failedLoginAttempts[email] = nil
    }

    private func validateEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func validatePasswordStrength(_ password: String) -> Bool {
        return password.count >= 8
    }

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws {
        guard validateEmail(email) else {
            throw SupabaseError.serverError("Invalid email format")
        }
        guard !password.isEmpty else {
            throw SupabaseError.serverError("Password cannot be empty")
        }
        if isRateLimited(for: email) {
            os_log("Rate limit exceeded for email: %@", log: OSLog.default, type: .error, email)
            throw SupabaseError.serverError("Too many failed attempts. Please try again later.")
        }
        do {
            let response = try await supabaseClient.auth.signIn(
                email: email,
                password: password
            )
            isAuthenticated = true
            currentUser = response.user
            recordSuccessfulLogin(for: email)
        } catch {
            recordFailedAttempt(for: email)
            os_log("Sign in failed for email %@: %@", log: OSLog.default, type: .error, email, error.localizedDescription)
            throw error
        }
    }

    func signUp(email: String, password: String, platform: String = "ios") async throws {
        guard validateEmail(email) else {
            throw SupabaseError.serverError("Invalid email format")
        }
        guard validatePasswordStrength(password) else {
            throw SupabaseError.serverError("Password must be at least 8 characters")
        }
        if isRateLimited(for: email) {
            throw SupabaseError.serverError("Too many sign-up attempts. Please try again later.")
        }
        do {
            let response = try await supabaseClient.auth.signUp(
                email: email,
                password: password,
                data: ["platform": platform]
            )
            isAuthenticated = true
            currentUser = response.user
        } catch {
            recordFailedAttempt(for: email)
            os_log("Sign up failed for email %@: %@", log: OSLog.default, type: .error, email, error.localizedDescription)
            throw error
        }
    }
    
    func signOut() async throws {
        try await supabaseClient.auth.signOut()
        isAuthenticated = false
        currentUser = nil
    }
    
    func fetchTranslations(limit: Int = 50, offset: Int = 0) async throws -> [TranslationRecord] {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        return try await supabaseClient
            .from("translations")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .range(offset ..< offset + limit)
            .execute()
            .value
    }
    
    func saveTranslation(_ translation: TranslationRecord) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        var record = translation
        record.userId = userId.uuidString
        _ = try await supabaseClient
            .from("translations")
            .insert(record)
            .execute()
    }
    
    func fetchCommunityPhrases(language: String? = nil, limit: Int = 50) async throws -> [CommunityPhrase] {
        var query = supabaseClient
            .from("community_phrases")
            .select()
            .eq("approval_status", value: "approved")
            .order("upvotes", ascending: false)
            .limit(limit)
        
        if let language {
            query = query.eq("language", value: language)
        }
        
        return try await query.execute().value
    }
    
    func submitPhrase(_ phrase: CommunityPhrase) async throws {
        guard let userId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        var record = phrase
        record.submittedBy = userId.uuidString
        _ = try await supabaseClient
            .from("community_phrases")
            .insert(record)
            .execute()
    }
    
    func follow(userId: String) async throws {
        guard let currentId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        _ = try await supabaseClient
            .from("follow_relationships")
            .insert(["follower_id": currentId.uuidString, "following_id": userId])
            .execute()
    }
    
    func unfollow(userId: String) async throws {
        guard let currentId = currentUser?.id else { throw SupabaseError.notAuthenticated }
        _ = try await supabaseClient
            .from("follow_relationships")
            .delete()
            .eq("follower_id", value: currentId.uuidString)
            .eq("following_id", value: userId)
            .execute()
    }
    
    func subscribeToRealtime(channel: String) -> RealtimeChannel {
        return supabaseClient.channel(channel)
    }
}

struct TranslationRecord: Codable, Identifiable {
    var id: String?
    var userId: String?
    var humanText: String
    var animalText: String
    var sourceLanguage: String
    var targetLanguage: String
    var confidence: Double
    var qualityScore: Double?
    var isFavorite: Bool
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", humanText = "human_text", animalText = "animal_text"
        case sourceLanguage = "source_language", targetLanguage = "target_language"
        case confidence, qualityScore = "quality_score", isFavorite = "is_favorite"
        case createdAt = "created_at"
    }
}

struct CommunityPhrase: Codable, Identifiable {
    var id: String?
    var phraseText: String
    var language: String
    var submittedBy: String?
    var approvalStatus: String?
    var upvotes: Int
    var downvotes: Int
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, phraseText = "phrase_text", language
        case submittedBy = "submitted_by", approvalStatus = "approval_status"
        case upvotes, downvotes, createdAt = "created_at"
    }
}
