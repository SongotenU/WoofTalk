// MARK: - Analytics Storage Protocol

import Foundation

protocol AnalyticsStorage {
    func save<T: Codable>(_ object: T, forKey key: String) throws
    func load<T: Codable>(forKey key: String) throws -> T?
    func remove(forKey key: String) throws
    func clearAll() throws
}

// MARK: - UserDefaults Analytics Storage

final class UserDefaultsAnalyticsStorage: AnalyticsStorage {
    
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func save<T: Codable>(_ object: T, forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        let data = try encoder.encode(object)
        defaults.set(data, forKey: key)
    }
    
    func load<T: Codable>(forKey key: String) throws -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let data = defaults.data(forKey: key) else {
            return nil
        }
        return try decoder.decode(T.self, from: data)
    }
    
    func remove(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        
        defaults.removeObject(forKey: key)
    }
    
    func clearAll() throws {
        lock.lock()
        defer { lock.unlock() }
        
        let domain = Bundle.main.bundleIdentifier ?? "com.wooftalk.analytics"
        defaults.removePersistentDomain(forName: domain)
    }
}

// MARK: - Storage Keys

enum AnalyticsStorageKey: String {
    case events = "analytics_events"
    case qualityMetrics = "analytics_quality_metrics"
    case performanceMetrics = "analytics_performance_metrics"
    case usageStats = "analytics_usage_stats"
    case sessions = "analytics_sessions"
    case languagePairUsage = "analytics_language_pair_usage"
    case currentSession = "analytics_current_session"
}
