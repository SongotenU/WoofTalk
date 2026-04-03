import Foundation
import Supabase

struct TranslationRequest: Codable {
    let human_text: String
    let animal_text: String
    let source_language: String
    let target_language: String
    let confidence: Float?
    let quality_score: Float?

    init(humanText: String, animalText: String, sourceLanguage: String = "human", targetLanguage: String = "dog", confidence: Float? = nil, qualityScore: Float? = nil) {
        self.human_text = humanText
        self.animal_text = animalText
        self.source_language = sourceLanguage
        self.target_language = targetLanguage
        self.confidence = confidence
        self.quality_score = qualityScore
    }
}

struct TranslationRecord: Codable, Identifiable {
    let id: String
    let user_id: String
    let human_text: String
    let animal_text: String
    let source_language: String
    let target_language: String
    let confidence: Float?
    let quality_score: Float?
    let created_at: String
    let updated_at: String?
}

enum TranslationError: LocalizedError {
    case authenticationRequired
    case rateLimitExceeded
    case invalidInput(String)
    case serverError(String)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .authenticationRequired: return "Authentication required. Please log in."
        case .rateLimitExceeded: return "Rate limit exceeded. Please wait."
        case .invalidInput(let msg): return "Invalid input: \(msg)"
        case .serverError(let msg): return "Server error: \(msg)"
        case .unknown(let err): return err.localizedDescription
        }
    }
}

actor TranslationService {
    static let shared = TranslationService()
    private var supabase: SupabaseClient?

    private init() {
        setupSupabase()
    }

    private func setupSupabase() {
        guard let url = URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""),
              let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""),
              !url.absoluteString.isEmpty && !key.isEmpty else {
            print("WARNING: Supabase credentials not set - translation will fail")
            return
        }

        supabase = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }

    func translate(
        humanText: String,
        animalText: String,
        sourceLanguage: String = "human",
        targetLanguage: String = "dog",
        confidence: Float? = nil,
        completion: @escaping @Sendable (Result<TranslationRecord, TranslationError>) -> Void
    ) {
        guard let supabase = supabase else {
            completion(.failure(.authenticationRequired))
            return
        }

        let request = TranslationRequest(
            humanText: humanText,
            animalText: animalText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            confidence: confidence,
            qualityScore: nil
        )

        Task {
            do {
                let response = try await supabase.functions.invoke(
                    "translate",
                    body: request,
                    method: "POST"
                )

                guard let data = response.data else {
                    throw TranslationError.serverError("Empty response")
                }

                let record = try JSONDecoder().decode(TranslationRecord.self, from: data)
                completion(.success(record))
            } catch let error as CustomNSError {
                if error.code == 401 {
                    completion(.failure(.authenticationRequired))
                } else if error.code == 429 {
                    completion(.failure(.rateLimitExceeded))
                } else {
                    completion(.failure(.serverError(error.localizedDescription)))
                }
            } catch {
                completion(.failure(.unknown(error)))
            }
        }
    }
}
