import Foundation
import os.log

/// Centralized error reporting for client-side error capture
final class ErrorReporter {
    static let shared = ErrorReporter()

    private var beforeSend: ((ErrorReport) -> ErrorReport)?
    private let log = OSLog(subsystem: "com.wooftalk", category: "ErrorReporter")

    private init() {}

    func configure(dsn: String, environment: String = "production", beforeSend: ((ErrorReport) -> ErrorReport)? = nil) {
        self.beforeSend = beforeSend
        os_log("ErrorReporter configured — environment: %{public}@", log: log, type: .info, environment)
    }

    func report(_ error: Error, context: [String: Any] = [:], severity: ErrorSeverity = .error) {
        let report = beforeSend?(ErrorReport(error: error, context: context, severity: severity, timestamp: Date())) ?? ErrorReport(error: error, context: context, severity: severity, timestamp: Date())
        #if DEBUG
        logReport(report)
        #else
        sendToBackend(report)
        #endif
    }

    func reportMessage(_ message: String, level: LogLevel = .info) {
        os_log("Report: %{public}@", log: log, type: level.toOSLogType(), message)
    }

    func addBreadcrumb(_ category: String, message: String, data: [String: Any]? = nil) {
        os_log("Breadcrumb [%{public}@]: %{public}@", log: log, type: .debug, category, message)
    }

    func setUser(id: String, email: String?) {
        os_log("User context set: %{public}@", log: log, type: .info, id)
    }

    func clearUser() {}

    private func sendToBackend(_ report: ErrorReport) {
        os_log("ErrorReport sent: %{public}@", log: log, type: .error, report.error.localizedDescription)
    }

    private func logReport(_ report: ErrorReport) {
        let ctx = report.context.map { "\($0)=\($1)" }.joined(separator: ", ")
        os_log("[%{public}@] %{public}@ — %{public}@",
               log: log, type: .error,
               report.severity.rawValue,
               report.error.localizedDescription,
               ctx.isEmpty ? "no context" : ctx)
    }
}

struct ErrorReport {
    let error: Error
    let context: [String: Any]
    let severity: ErrorSeverity
    let timestamp: Date
}

enum ErrorSeverity: String {
    case fatal = "fatal", error = "error", warning = "warning", info = "info"
}

enum LogLevel: String {
    case debug, info, warning, error

    func toOSLogType() -> OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .error
        case .error: return .fault
        }
    }
}
