import Foundation
import Combine
import Supabase

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
        client = SupabaseClient(
            supabaseURL: URL(string: url)!,
            supabaseKey: anonKey
        )
        setupAuthObserver()
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
    
    func signIn(email: String, password: String) async throws {
        let response = try await supabaseClient.auth.signIn(
            email: email,
            password: password
        )
        isAuthenticated = true
        currentUser = response.user
    }
    
    func signUp(email: String, password: String, platform: String = "ios") async throws {
        let response = try await supabaseClient.auth.signUp(
            email: email,
            password: password,
            data: ["platform": platform]
        )
        isAuthenticated = true
        currentUser = response.user
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
