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
        guard !newEvents.isEmpty else { return }
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
        getEvents(since: date).count
    }

    func cleanupOldEvents() {
        lock.lock()
        defer { lock.unlock() }
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        var events = loadEvents()
        events = events.filter { $0.timestamp >= cutoff }
        saveEvents(events)
    }

    private func loadEvents() -> [TranslationAnalyticsEvent] {
        (try? storage.load(forKey: AnalyticsStorageKey.events.rawValue)) ?? []
    }

    private func saveEvents(_ events: [TranslationAnalyticsEvent]) {
        try? storage.save(events, forKey: AnalyticsStorageKey.events.rawValue)
    }
}
