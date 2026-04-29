import os.log
import Foundation

final class ErrorReportingManager {
    static let shared = ErrorReportingManager()

    private var errorLog: [ErrorLogEntry] = []
    private let queue = DispatchQueue(label: "com.wooftalk.errorreporting")
    private let maxLogSize = 1000

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

    private init() {}

    func logError(domain: String, code: Int, message: String, stackTrace: String? = nil, context: [String: String]? = nil) {
        let entry = ErrorLogEntry(domain: domain, code: code, message: message, stackTrace: stackTrace, context: context)

        queue.async {
            self.errorLog.append(entry)
            if self.errorLog.count > self.maxLogSize {
                self.errorLog.removeFirst(self.errorLog.count - self.maxLogSize)
            }
        }

        os_log("%{public}@", log: OSLog.default, type: .default, "ERROR [\(domain)] (\(code)): \(message)")
    }

    func getRecentErrors(limit: Int = 50) -> [ErrorLogEntry] {
        queue.sync { Array(errorLog.suffix(limit)) }
    }

    func clearErrorLog() {
        queue.async { self.errorLog.removeAll() }
    }

    func exportErrorLog() -> Data? {
        queue.sync { try? JSONEncoder().encode(errorLog) }
    }
}