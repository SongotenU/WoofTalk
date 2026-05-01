import Foundation

struct FeatureFlag: Codable {
    let key: String
    let name: String
    let isEnabled: Bool
    let rolloutPercentage: Int
    let value: [String: String]?
    var enabled: Bool { isEnabled }
}

final class FeatureFlagManager {
    static let shared = FeatureFlagManager()
    
    private var edgeFunctionURL: String {
        return "\(SupabaseManager.shared.supabaseURL)/functions/v1/feature-flag-evaluate"
    }
    private var cache: [String: (enabled: Bool, expires: Date)] = [:]
    private let cacheTTL: TimeInterval = 300
    
    private init() {}
    
    func isEnabled(_ key: String, userId: String? = nil, completion: @escaping (Bool) -> Void) {
        let userId = userId ?? SupabaseManager.shared.currentUserId ?? ""
        
        if let cached = cache[key], cached.expires > Date() {
            completion(cached.enabled)
            return
        }
        
        guard let url = URL(string: edgeFunctionURL) else { completion(false); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "key": key,
            "user_id": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch { completion(false); return }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let enabled = json["enabled"] as? Bool else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async {
                self?.cache[key] = (enabled, Date().addingTimeInterval(self?.cacheTTL ?? 300))
                completion(enabled)
            }
        }.resume()
    }
}
