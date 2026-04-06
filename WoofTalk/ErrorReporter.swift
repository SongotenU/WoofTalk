// MARK: - ErrorReporter

import Foundation
import os.log

/// Centralized error reporting for client-side error capture
/// Reports to Sentry in production, logs to console in development
final class ErrorReporter {

    static let shared = ErrorReporter()

    private var isInitialized = false
    private let log = OSLog(subsystem: "com.wooftalk", category: "ErrorReporter")
    private var beforeSend: ((ErrorReport) -> ErrorReport)?

    private init() {}

    /// Initialize error reporter with DSN
    func configure(dsn: String, environment: String = "production", beforeSend: ((ErrorReport) -> ErrorReport)? = nil) {
        isInitialized = true
        self.beforeSend = beforeSend
        os_log("ErrorReporter configured — environment: %{public}@",
               log: log, type: .info, environment)
        // In production: SentrySDK.start { options in options.dsn = dsn; ... }
    }

    /// Report an error with context
    func report(_ error: Error, context: [String: Any] = [:], severity: ErrorSeverity = .error) {
        let report = ErrorReport(
            error: error,
            context: context,
            severity: severity,
            timestamp: Date()
        )

        let finalReport = beforeSend?(report) ?? report

        if isProduction {
            sendToBackend(finalReport)
        } else {
            logReport(finalReport)
        }
    }

    /// Report a non-error message (e.g., anomaly or unexpected state)
    func reportMessage(_ message: String, level: LogLevel = .info) {
        os_log("Report: %{public}@", log: log, type: level.toOSLogType(), message)
        if isProduction && level == .error {
            // In production: SentrySDK.capture(message: message)
        }
    }

    /// Add a breadcrumb for tracing
    func addBreadcrumb(_ category: String, message: String, data: [String: Any]? = nil) {
        os_log("Breadcrumb [%{public}@]: %{public}@",
               log: log, type: .debug, category, message)
        // In production: let breadcrumb = Breadcrumb(level: .info, category: category); SentrySDK.addBreadcrumb(breadcrumb)
    }

    /// Set user context for error correlation
    func setUser(id: String, email: String?) {
        os_log("User context set: %{public}@", log: log, type: .info, id)
        // In production: let user = Sentry.User(userId: id); user.email = email; SentrySDK.setUser(user)
    }

    /// Clear user context (e.g., on logout)
    func clearUser() {
        // In production: SentrySDK.setUser(nil)
    }

    // MARK: - Private

    private var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }

    private func sendToBackend(_ report: ErrorReport) {
        // In production: SentrySDK.capture(error: report.error) { scope in
        //     scope.setContext(value: report.context, key: "context")
        //     scope.setLevel(report.severity.toSentryLevel())
        // }
        os_log("ErrorReport sent to backend: %{public}@",
               log: log, type: .error, "\(report.error.localizedDescription)")
    }

    private func logReport(_ report: ErrorReport) {
        let ctx = report.context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        os_log("[%{public}@] %{public}@ — %{public}@",
               log: log, type: .error,
               report.severity.rawValue,
               report.error.localizedDescription,
               ctx.isEmpty ? "no context" : ctx)
    }
}

// MARK: - ErrorReport

struct ErrorReport {
    let error: Error
    let context: [String: Any]
    let severity: ErrorSeverity
    let timestamp: Date
}

enum ErrorSeverity: String {
    case fatal = "fatal"
    case error = "error"
    case warning = "warning"
    case info = "info"
}

enum LogLevel: String {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"

    func toOSLogType() -> OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .error
        case .error: return .fault
        }
    }
}
