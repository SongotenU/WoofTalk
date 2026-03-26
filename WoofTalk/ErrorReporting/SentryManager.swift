import Foundation

final class SentryManager {
    
    static let shared = SentryManager()
    
    private var isEnabled = false
    private var dsn: String = ""
    
    private var eventCount = 0
    private var breadcrumbs: [Breadcrumb] = []
    private let maxBreadcrumbs = 100
    
    private init() {}
    
    func initialize(dsn: String) {
        self.dsn = dsn
        self.isEnabled = !dsn.isEmpty
        
        if isEnabled {
            print("SentryManager: Initialized with DSN")
        } else {
            print("SentryManager: Running in development mode (no DSN)")
        }
    }
    
    func captureError(_ error: Error, context: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        eventCount += 1
        
        let event = SentryEvent(
            eventId: UUID().uuidString,
            timestamp: Date(),
            level: .error,
            message: error.localizedDescription,
            context: context ?? [:],
            breadcrumbs: breadcrumbs
        )
        
        sendToSentry(event)
    }
    
    func captureMessage(_ message: String, level: SentryLevel = .info, context: [String: Any]? = nil) {
        guard isEnabled else { return }
        
        eventCount += 1
        
        let event = SentryEvent(
            eventId: UUID().uuidString,
            timestamp: Date(),
            level: level,
            message: message,
            context: context ?? [:],
            breadcrumbs: breadcrumbs
        )
        
        sendToSentry(event)
    }
    
    func addBreadcrumb(category: String, message: String, level: BreadcrumbLevel = .info) {
        let breadcrumb = Breadcrumb(
            timestamp: Date(),
            category: category,
            message: message,
            level: level
        )
        
        breadcrumbs.append(breadcrumb)
        
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst()
        }
    }
    
    func clearBreadcrumbs() {
        breadcrumbs.removeAll()
    }
    
    func setUser(id: String, email: String? = nil) {
        addBreadcrumb(category: "user", message: "User set: \(id)")
    }
    
    private func sendToSentry(_ event: SentryEvent) {
        print("SentryManager: Capturing event \(event.eventId)")
    }
    
    func getEventCount() -> Int {
        return eventCount
    }
}

enum SentryLevel: String {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case fatal = "fatal"
}

enum BreadcrumbLevel: String {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
}

struct Breadcrumb {
    let timestamp: Date
    let category: String
    let message: String
    let level: BreadcrumbLevel
}

struct SentryEvent {
    let eventId: String
    let timestamp: Date
    let level: SentryLevel
    let message: String
    let context: [String: Any]
    let breadcrumbs: [Breadcrumb]
}
