import Foundation

final class ErrorTrackingService {
    static let shared = ErrorTrackingService()
    
    private var edgeFunctionURL: String {
        return "\(SupabaseManager.shared.supabaseURL)/functions/v1/error-collector"
    }
    private let session = URLSession.shared
    
    private init() {}
    
    func trackError(
        platform: String = "ios",
        errorType: String,
        message: String,
        stackTrace: String? = nil,
        endpoint: String? = nil,
        statusCode: Int? = nil,
        metadata: [String: Any]? = nil
    ) {
        guard let url = URL(string: edgeFunctionURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use user JWT from Supabase session instead of service role key
        guard let accessToken = SupabaseManager.shared.client?.auth.session?.accessToken else {
            // If no user token available, skip sending (user not authenticated)
            return
        }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        var payload: [String: Any] = [
            "platform": platform,
            "error_type": errorType,
            "message": message
        ]
        if let stackTrace = stackTrace { payload["stack_trace"] = stackTrace }
        if let endpoint = endpoint { payload["endpoint"] = endpoint }
        if let statusCode = statusCode { payload["status_code"] = statusCode }
        if let metadata = metadata { payload["metadata"] = metadata }
        if let userId = SupabaseManager.shared.currentUserId {
            payload["user_id"] = userId
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch { return }
        
        session.dataTask(with: request).resume()
    }
    
    func captureError(_ error: Error, endpoint: String? = nil) {
        let nsError = error as NSError
        trackError(
            errorType: "\(type(of: error))",
            message: error.localizedDescription,
            stackTrace: nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String,
            endpoint: endpoint,
            statusCode: nsError.code,
            metadata: ["domain": nsError.domain, "userInfo": nsError.userInfo.description]
        )
    }
}
