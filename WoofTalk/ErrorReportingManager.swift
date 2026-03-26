import Foundation

final class ErrorReportingManager {
    static let shared = ErrorReportingManager()
    
    private var errorLog: [ErrorLogEntry] = []
    private let queue = DispatchQueue(label: "com.wooftalk.errorreporting")
    
    struct ErrorLogEntry: Codable {
        let id: UUID
        let timestamp: Date
        let domain: String
        let code: Int
        let message: String
        let stackTrace: String?
        let context: [String: String]?
        
        init(domain: String, code: Int, message: String, stackTrace: String? = nil, context: [String: String]? = nil) {
            self.id = UUID()
            self.timestamp = Date()
            self.domain = domain
            self.code = code
            self.message = message
            self.stackTrace = stackTrace
            self.context = context
        }
    }
    
    enum ErrorDomain: String {
        case translation = "Translation"
        case audio = "Audio"
        case network = "Network"
        case persistence = "Persistence"
        case community = "Community"
        case social = "Social"
        case moderation = "Moderation"
    }
    
    private init() {}
    
    func logError(domain: ErrorDomain, code: Int, message: String, stackTrace: String? = nil, context: [String: String]? = nil) {
        let entry = ErrorLogEntry(
            domain: domain.rawValue,
            code: code,
            message: message,
            stackTrace: stackTrace,
            context: context
        )
        
        queue.async { [weak self] in
            self?.errorLog.append(entry)
            if self?.errorLog.count ?? 0 > 1000 {
                self?.errorLog.removeFirst((self?.errorLog.count ?? 0) - 1000)
            }
        }
        
        #if DEBUG
        print("ERROR [\(domain.rawValue)] (\(code)): \(message)")
        #endif
    }
    
    func getRecentErrors(limit: Int = 50) -> [ErrorLogEntry] {
        var result: [ErrorLogEntry] = []
        queue.sync {
            result = Array(errorLog.suffix(limit))
        }
        return result
    }
    
    func clearErrorLog() {
        queue.async { [weak self] in
            self?.errorLog.removeAll()
        }
    }
    
    func exportErrorLog() -> Data? {
        var logs: [ErrorLogEntry] = []
        queue.sync {
            logs = errorLog
        }
        return try? JSONEncoder().encode(logs)
    }
}