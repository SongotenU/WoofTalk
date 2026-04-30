import Foundation

protocol AnalyticsStorage {
    func save<T: Codable>(_ object: T, forKey key: String) throws
    func load<T: Codable>(forKey key: String) throws -> T?
    func remove(forKey key: String) throws
    func clearAll() throws
}

final class UserDefaultsAnalyticsStorage: AnalyticsStorage {
    private let defaults: UserDefaults
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save<T: Codable>(_ object: T, forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        let data = try JSONEncoder().encode(object)
        defaults.set(data, forKey: key)
    }

    func load<T: Codable>(forKey key: String) throws -> T? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func remove(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        defaults.removeObject(forKey: key)
    }

    func clearAll() throws {
        lock.lock()
        defer { lock.unlock() }
        defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "com.wooftalk.analytics")
    }
}

enum AnalyticsStorageKey: String {
    case events = "analytics_events"
    case qualityMetrics = "analytics_quality_metrics"
    case performanceMetrics = "analytics_performance_metrics"
    case usageStats = "analytics_usage_stats"
    case sessionData = "analytics_session_data"
}
