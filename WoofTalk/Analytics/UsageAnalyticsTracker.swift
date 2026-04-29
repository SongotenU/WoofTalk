// MARK: - Usage Analytics Tracker

import Foundation

final class UsageAnalyticsTracker {
    
    private let storage: AnalyticsStorage
    private let eventStore: AnalyticsEventStore
    private let lock = NSLock()
    
    private var featureUsage: [String: FeatureUsageStats] = [:]
    private var languagePairUsage: [String: LanguagePairUsage] = [:]
    private var currentSession: SessionAnalytics?
    
    init(storage: AnalyticsStorage = UserDefaultsAnalyticsStorage(), eventStore: AnalyticsEventStore) {
        self.storage = storage
        self.eventStore = eventStore
        loadUsageData()
    }
    
    // MARK: - Session Management
    
    func startSession() -> String {
        lock.lock()
        defer { lock.unlock() }
        
        let session = SessionAnalytics()
        currentSession = session
        saveCurrentSession()
        
        let event = TranslationAnalyticsEvent(
            eventType: .sessionStarted,
            sessionId: session.id.uuidString,
            metadata: [:]
        )
        eventStore.recordEvent(event)
        
        return session.id.uuidString
    }
    
    func endSession() {
        lock.lock()
        defer { lock.unlock() }
        
        guard var session = currentSession else { return }
        session.endSession()
        
        let event = TranslationAnalyticsEvent(
            eventType: .sessionEnded,
            sessionId: session.id.uuidString,
            metadata: [
                "duration": String(session.duration),
                "translationCount": String(session.translationCount)
            ]
        )
        eventStore.recordEvent(event)
        
        currentSession = nil
        saveCurrentSession()
    }
    
    // MARK: - Feature Usage
    
    func recordFeatureUsage(featureName: String, sessionId: String, sessionDuration: TimeInterval = 0) {
        lock.lock()
        defer { lock.unlock() }

        var stats = featureUsage[featureName] ?? FeatureUsageStats(featureName: featureName)
        stats.recordUsage(sessionDuration: sessionDuration)
        featureUsage[featureName] = stats

        currentSession?.featuresUsed.append(featureName)
        currentSession?.translationCount += 1

        saveFeatureUsage()

        let event = TranslationAnalyticsEvent(
            eventType: .featureUsed,
            sessionId: sessionId,
            metadata: ["feature": featureName]
        )
        eventStore.recordEvent(event)
    }
    
    func recordTranslation(sessionId: String, duration: TimeInterval = 0) {
        lock.lock()
        defer { lock.unlock() }
        
        currentSession?.translationCount += 1
        currentSession?.totalTranslationDuration += duration
        saveCurrentSession()
        
        let event = TranslationAnalyticsEvent(
            eventType: .translationCompleted,
            sessionId: sessionId,
            metadata: ["duration": String(duration)]
        )
        eventStore.recordEvent(event)
    }
    
    // MARK: - Language Pair Usage
    
    func recordLanguagePairUsage(sourceLanguage: String, targetLanguage: String, sessionId: String) {
        lock.lock()
        defer { lock.unlock() }

        let key = "\(sourceLanguage)->\(targetLanguage)"
        var usage = languagePairUsage[key] ?? LanguagePairUsage(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage)
        usage.recordUsage()
        languagePairUsage[key] = usage

        saveLanguagePairUsage()
    }
    
    // MARK: - Query Methods
    
    func getFeatureUsageStats() -> [FeatureUsageStats] {
        lock.lock()
        defer { lock.unlock() }
        
        return Array(featureUsage.values).sorted { $0.usageCount > $1.usageCount }
    }
    
    func getTopFeatures(limit: Int = 10) -> [FeatureUsageStats] {
        return Array(getFeatureUsageStats().prefix(limit))
    }
    
    func getLanguagePairUsage() -> [LanguagePairUsage] {
        lock.lock()
        defer { lock.unlock() }
        
        return Array(languagePairUsage.values).sorted { $0.usageCount > $1.usageCount }
    }
    
    func getTopLanguagePairs(limit: Int = 5) -> [LanguagePairUsage] {
        return Array(getLanguagePairUsage().prefix(limit))
    }
    
    func getTotalTranslationCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        
        return featureUsage.values.reduce(0) { $0 + $1.usageCount }
    }
    
    func getActiveFeatureCount() -> Int {
        lock.lock()
        defer { lock.unlock() }

        let oneDayAgo = Date().addingTimeInterval(-86400)
        return featureUsage.values.filter { $0.lastUsed > oneDayAgo }.count
    }
    
    // MARK: - Time-based Analytics

    func getDailyUsage(days: Int = 7) -> [Date: Int] {
        lock.lock()
        defer { lock.unlock() }

        let calendar = Calendar.current
        var dailyUsage: [Date: Int] = [:]

        for stats in featureUsage.values {
            let dayStart = calendar.startOfDay(for: stats.lastUsed)
            if let daysAgo = calendar.date(byAdding: .day, value: -days, to: Date()),
               dayStart >= daysAgo {
                dailyUsage[dayStart, default: 0] += stats.usageCount
            }
        }

        return dailyUsage
    }

    var weeklyUsage: Int {
        getDailyUsage(days: 7).values.reduce(0, +)
    }

    var monthlyUsage: Int {
        getDailyUsage(days: 30).values.reduce(0, +)
    }
    
    // MARK: - Clear Data
    
    func clearUsageData() {
        lock.lock()
        defer { lock.unlock() }
        
        featureUsage = [:]
        languagePairUsage = [:]
        
        try? storage.remove(forKey: AnalyticsStorageKey.usageStats.rawValue)
        try? storage.remove(forKey: AnalyticsStorageKey.languagePairUsage.rawValue)
        try? storage.remove(forKey: AnalyticsStorageKey.sessions.rawValue)
    }
    
    // MARK: - Private Methods
    
    private func loadUsageData() {
        if let stats: [String: FeatureUsageStats] = try? storage.load(forKey: AnalyticsStorageKey.usageStats.rawValue) {
            featureUsage = stats
        }
        
        if let usage: [String: LanguagePairUsage] = try? storage.load(forKey: AnalyticsStorageKey.languagePairUsage.rawValue) {
            languagePairUsage = usage
        }
        
        if let session: SessionAnalytics = try? storage.load(forKey: AnalyticsStorageKey.currentSession.rawValue) {
            currentSession = session
        }
    }
    
    private func saveFeatureUsage() {
        try? storage.save(featureUsage, forKey: AnalyticsStorageKey.usageStats.rawValue)
    }
    
    private func saveLanguagePairUsage() {
        try? storage.save(languagePairUsage, forKey: AnalyticsStorageKey.languagePairUsage.rawValue)
    }
    
    private func saveCurrentSession() {
        if let session = currentSession {
            try? storage.save(session, forKey: AnalyticsStorageKey.currentSession.rawValue)
        }
    }
}
