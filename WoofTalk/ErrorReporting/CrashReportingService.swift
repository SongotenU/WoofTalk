import os.log

final class CrashReportingService {
    static let shared = CrashReportingService()
    private let sentryManager = SentryManager.shared

    private init() {}

    func initialize() {
        setupExceptionHandlers()
        os_log("CrashReportingService: Initialized")
    }

    private func setupExceptionHandlers() {
        NSSetUncaughtExceptionHandler { exception in
            CrashReportingService.shared.handleException(exception)
        }
    }

    private func handleException(_ exception: NSException) {
        sentryManager.addBreadcrumb(category: "crash", message: "Uncaught: \(exception.name.rawValue)")
        sentryManager.captureError(
            NSError(domain: "WoofTalk", code: -1, userInfo: [
                NSLocalizedDescriptionKey: exception.reason ?? "Unknown",
                "callStack": exception.callStackSymbols
            ])
        )
    }

    func reportTranslationError(_ error: Error, context: [String: Any]? = nil) {
        sentryManager.addBreadcrumb(category: "translation", message: "Error: \(error.localizedDescription)")
        sentryManager.captureError(error, context: context ?? [:])
    }

    func reportRealTimeError(_ error: Error, context: [String: Any]? = nil) {
        sentryManager.addBreadcrumb(category: "realtime", message: error.localizedDescription)
        sentryManager.captureError(error, context: context ?? [:])
    }

    func logTranslationAttempt(input: String, output: String?, success: Bool) {
        sentryManager.addBreadcrumb(
            category: "translation",
            message: success ? "Success" : "Failed",
            level: success ? .info : .warning
        )
    }
}
