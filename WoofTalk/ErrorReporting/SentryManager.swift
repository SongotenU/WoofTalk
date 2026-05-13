import os.log
import Sentry

final class SentryManager {
    static let shared = SentryManager()

    private var isInitialized = false

    private init() {}

    func initialize(dsn: String, environment: String = "production") {
        guard !dsn.isEmpty else {
            os_log("SentryManager: Dev mode (no DSN)", log: OSLog.default, type: .default)
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment
            options.debug = false
            options.enableAutoSessionTracking = true
            options.attachStacktrace = true
            options.maxBreadcrumbs = 100
        }

        isInitialized = true
        os_log("SentryManager: Initialized with environment %{public}@", environment)
    }

    func captureError(_ error: Error, context: [String: Any]? = nil) {
        guard isInitialized else { return }
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                for (key, value) in context {
                    scope.setExtra(value: "\(value)", key: key)
                }
            }
        }
    }

    func captureMessage(_ message: String, level: SentryLevel = .info, context: [String: Any]? = nil) {
        guard isInitialized else { return }
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
            if let context = context {
                for (key, value) in context {
                    scope.setExtra(value: "\(value)", key: key)
                }
            }
        }
    }

    func addBreadcrumb(category: String, message: String, level: BreadcrumbLevel = .info) {
        guard isInitialized else { return }
        let breadcrumb = Breadcrumb()
        breadcrumb.category = category
        breadcrumb.message = message
        breadcrumb.level = level.toSentryLevel()
        SentrySDK.addBreadcrumb(breadcrumb)
    }

    func clearBreadcrumbs() {
        // Sentry manages its own breadcrumb queue
    }

    func setUser(id: String) {
        guard isInitialized else { return }
        let user = User()
        user.userId = id
        SentrySDK.setUser(user)
        addBreadcrumb(category: "user", message: "User: \(id)")
    }

    func clearUser() {
        guard isInitialized else { return }
        SentrySDK.setUser(nil)
    }
}

enum SentryLevel: String { case debug, info, warning, error, fatal }

enum BreadcrumbLevel: String { case debug, info, warning, error }

extension BreadcrumbLevel {
    func toSentryLevel() -> SentryLevel {
        switch self {
        case .debug: return SentryLevel.debug
        case .info: return SentryLevel.info
        case .warning: return SentryLevel.warning
        case .error: return SentryLevel.error
        }
    }
}
