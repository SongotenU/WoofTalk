import os.log

final class SentryManager {
    static let shared = SentryManager()

    private var isEnabled = false
    private var breadcrumbs: [Breadcrumb] = []
    private let maxBreadcrumbs = 100

    private init() {}

    func initialize(dsn: String) {
        isEnabled = !dsn.isEmpty
        let msg = isEnabled ? "SentryManager: Initialized" : "SentryManager: Dev mode (no DSN)"
        os_log("%{public}@", log: OSLog.default, type: .default, msg)
    }

    func captureError(_ error: Error, context: [String: Any]? = nil) {
        guard isEnabled else { return }
        os_log("SentryManager: Captured error %{public}@", error.localizedDescription)
    }

    func captureMessage(_ message: String, level: SentryLevel = .info, context: [String: Any]? = nil) {
        guard isEnabled else { return }
        os_log("SentryManager: Captured message %{public}@", message)
    }

    func addBreadcrumb(category: String, message: String, level: BreadcrumbLevel = .info) {
        breadcrumbs.append(Breadcrumb(timestamp: Date(), category: category, message: message, level: level))
        if breadcrumbs.count > maxBreadcrumbs { breadcrumbs.removeFirst() }
    }

    func clearBreadcrumbs() { breadcrumbs.removeAll() }
    func setUser(id: String) { addBreadcrumb(category: "user", message: "User: \(id)") }
}

enum SentryLevel: String { case debug, info, warning, error, fatal }
enum BreadcrumbLevel: String { case debug, info, warning, error }

struct Breadcrumb {
    let timestamp: Date, category: String, message: String, level: BreadcrumbLevel
}
