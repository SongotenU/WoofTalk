// MARK: - Analytics Event Store

import Foundation

final class AnalyticsEventStore {
    
    private let storage: AnalyticsStorage
    private let maxEvents: Int
    private let retentionDays: Int
    private let lock = NSLock()
    
    init(storage: AnalyticsStorage = UserDefaultsAnalyticsStorage(), maxEvents: Int = 10000, retentionDays: Int = 7) {
        self.storage = storage
        self.maxEvents = maxEvents
        self.retentionDays = retentionDays
    }
    
    // MARK: - Event Operations
    
    func recordEvent(_ event: TranslationAnalyticsEvent) {
        lock.lock()
        defer { lock.unlock() }
        
        var events = loadEvents()
        events.append(event)
        
        if events.count > maxEvents {
            events = Array(events.suffix(maxEvents))
        }
        
        saveEvents(events)
    }
    
    func recordEvents(_ newEvents: [TranslationAnalyticsEvent]) {
        lock.lock()
        defer { lock.unlock() }
        
        var events = loadEvents()
        events.append(contentsOf: newEvents)
        
        if events.count > maxEvents {
            events = Array(events.suffix(maxEvents))
        }
        
        saveEvents(events)
    }
    
    func getEvents(since date: Date? = nil, eventType: AnalyticsEventType? = nil) -> [TranslationAnalyticsEvent] {
        lock.lock()
        defer { lock.unlock() }
        
        var events = loadEvents()
        
        if let date = date {
            events = events.filter { $0.timestamp >= date }
        }
        
        if let eventType = eventType {
            events = events.filter { $0.eventType == eventType }
        }
        
        return events.sorted { $0.timestamp > $1.timestamp }
    }
    
    func getEventCount(since date: Date? = nil) -> Int {
        return getEvents(since: date).count
    }
    
    // MARK: - Cleanup
    
    func cleanupOldEvents() {
        lock.lock()
        defer { lock.unlock() }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        var events = loadEvents()
        events = events.filter { $0.timestamp >= cutoffDate }
        saveEvents(events)
    }
    
    func clearAllEvents() {
        lock.lock()
        defer { lock.unlock() }
        
        try? storage.remove(forKey: AnalyticsStorageKey.events.rawValue)
    }
    
    // MARK: - Private Methods
    
    private func loadEvents() -> [TranslationAnalyticsEvent] {
        guard let events: [TranslationAnalyticsEvent] = try? storage.load(forKey: AnalyticsStorageKey.events.rawValue) else {
            return []
        }
        return events
    }
    
    private func saveEvents(_ events: [TranslationAnalyticsEvent]) {
        try? storage.save(events, forKey: AnalyticsStorageKey.events.rawValue)
    }
}
