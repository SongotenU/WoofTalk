import Foundation

final class CrashReportingService {
    
    static let shared = CrashReportingService()
    
    private let sentryManager = SentryManager.shared
    private var isInitialized = false
    
    private var exceptionHandlers: [() -> Void] = []
    
    private init() {}
    
    func initialize() {
        guard !isInitialized else { return }
        
        isInitialized = true
        
        setupSignalHandlers()
        setupExceptionHandlers()
        
        print("CrashReportingService: Initialized")
    }
    
    private func setupSignalHandlers() {
        signal(SIGSEGV) { _ in
            CrashReportingService.shared.handleSignal("SIGSEGV")
        }
        
        signal(SIGABRT) { _ in
            CrashReportingService.shared.handleSignal("SIGABRT")
        }
        
        signal(SIGBUS) { _ in
            CrashReportingService.shared.handleSignal("SIGBUS")
        }
        
        signal(SIGILL) { _ in
            CrashReportingService.shared.handleSignal("SIGILL")
        }
        
        signal(SIGFPE) { _ in
            CrashReportingService.shared.handleSignal("SIGFPE")
        }
    }
    
    private func setupExceptionHandlers() {
        NSSetUncaughtExceptionHandler { exception in
            CrashReportingService.shared.handleException(exception)
        }
    }
    
    private func handleSignal(_ signalName: String) {
        sentryManager.addBreadcrumb(
            category: "crash",
            message: "Received signal: \(signalName)",
            level: .error
        )
        
        sentryManager.captureMessage(
            "Application received signal: \(signalName)",
            level: .fatal,
            context: ["signal": signalName]
        )
    }
    
    private func handleException(_ exception: NSException) {
        sentryManager.addBreadcrumb(
            category: "crash",
            message: "Uncaught exception: \(exception.name)",
            level: .error
        )
        
        sentryManager.captureError(
            NSError(
                domain: "WoofTalk",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: exception.reason ?? "Unknown exception",
                    "exception": exception
                ]
            ),
            context: [
                "exceptionName": exception.name.rawValue,
                "exceptionReason": exception.reason ?? "",
                "callStack": exception.callStackSymbols
            ]
        )
    }
    
    func reportTranslationError(_ error: Error, context: [String: Any]? = nil) {
        sentryManager.addBreadcrumb(
            category: "translation",
            message: "Translation error: \(error.localizedDescription)",
            level: .error
        )
        
        var fullContext = context ?? [:]
        fullContext["errorDomain"] = (error as NSError).domain
        fullContext["errorCode"] = (error as NSError).code
        
        sentryManager.captureError(error, context: fullContext)
    }
    
    func reportRealTimeError(_ error: Error, context: [String: Any]? = nil) {
        sentryManager.addBreadcrumb(
            category: "realtime",
            message: "Real-time error: \(error.localizedDescription)",
            level: .error
        )
        
        sentryManager.captureError(error, context: context)
    }
    
    func reportPerformanceError(_ error: Error, context: [String: Any]? = nil) {
        sentryManager.addBreadcrumb(
            category: "performance",
            message: "Performance error: \(error.localizedDescription)",
            level: .warning
        )
        
        sentryManager.captureError(error, context: context)
    }
    
    func logTranslationAttempt(input: String, output: String?, success: Bool) {
        sentryManager.addBreadcrumb(
            category: "translation",
            message: success ? "Translation successful" : "Translation failed",
            level: success ? .info : .warning
        )
    }
    
    func logAnalyticsEvent(name: String, parameters: [String: Any]? = nil) {
        sentryManager.addBreadcrumb(
            category: "analytics",
            message: "Event: \(name)",
            level: .debug
        )
    }
}
