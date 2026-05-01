import Foundation

struct ExperimentVariant: Codable {
    let name: String
    let weight: Int
}

final class ABTestManager {
    static let shared = ABTestManager()
    
    private var edgeFunctionURL: String {
        return "\(SupabaseManager.shared.supabaseURL)/functions/v1/ab-assign"
    }
    private var assignments: [String: String] = [:]  // experimentName -> variant
    
    private init() {}
    
    func getVariant(for experimentName: String, userId: String, completion: @escaping (String?) -> Void) {
        if let cached = assignments[experimentName] {
            completion(cached)
            return
        }
        
        guard let url = URL(string: edgeFunctionURL) else { completion(nil); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "experiment_name": experimentName,
            "user_id": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch { completion(nil); return }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let variant = json["variant"] as? String else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async {
                self?.assignments[experimentName] = variant
                completion(variant)
            }
        }.resume()
    }
}
