// MARK: - OfflineManager

import Foundation
import AVFoundation

/// Manages offline translation functionality with caching and fallback logic
final class OfflineManager {
    
    // MARK: - Public Types
    
    /// Offline mode status
    enum OfflineStatus: Equatable {
        case online
        case offline
        case degraded
        case unknown
    }
    
    /// Translation availability
    enum TranslationAvailability: Equatable {
        case fullyAvailable
        case partiallyAvailable
        case limited
        case unavailable
    }
    
    /// Cache statistics
    struct CacheStatistics: CustomStringConvertible {
        let totalPhrases: Int
        let cachedPhrases: Int
        let hitRate: Double
        let storageUsage: Int
        let lastUpdated: Date?
        
        var description: String {
            return "OfflineManagerStats(total: \(totalPhrases), cached: \(cachedPhrases), hitRate: \(String(format: "%.1f", hitRate*100))%, storage: \(storageUsage)KB)"
        }
    }
    
    /// Offline capability assessment
    struct CapabilityAssessment: CustomStringConvertible {
        let status: OfflineStatus
        let availablePhrases: Int
        let coveragePercentage: Double
        let confidence: Double
        let limitations: [String]
        
        var description: String {
            return "CapabilityAssessment(status: \(status), coverage: \(String(format: "%.1f", coveragePercentage))%, confidence: \(String(format: "%.2f", confidence)))"
        }
    }
    
    // MARK: - Private Properties
    
    private let connectivityManager: ConnectivityManager
    private let vocabularyDatabase: VocabularyDatabase
    private let translationCache: TranslationCache
    private let audioEngine: AudioEngine
    
    private var cacheStatistics: CacheStatistics = CacheStatistics(
        totalPhrases: 0,
        cachedPhrases: 0,
        hitRate: 0.0,
        storageUsage: 0,
        lastUpdated: nil
    )
    
    private var capabilityAssessment: CapabilityAssessment = CapabilityAssessment(
        status: .unknown,
        availablePhrases: 0,
        coveragePercentage: 0.0,
        confidence: 0.0,
        limitations: []
    )
    
    private let assessmentQueue = DispatchQueue(label: "com.wooftalk.offline.assessment")
    private let cacheQueue = DispatchQueue(label: "com.wooftalk.offline.cache")
    
    // MARK: - Public Properties
    
    /// Current offline status
    var offlineStatus: OfflineStatus {
        return connectivityManager.status == .online ? .online : .offline
    }
    
    /// Current translation availability
    var translationAvailability: TranslationAvailability {
        assessmentQueue.sync {
            let assessment = self.capabilityAssessment
            switch assessment.status {
            case .online:
                return .fullyAvailable
            case .offline:
                return assessment.coveragePercentage > 0.7 ? .partiallyAvailable : .limited
            case .degraded:
                return .partiallyAvailable
            case .unknown:
                return .unavailable
            }
        }
    }
    
    /// Cache statistics
    var statistics: CacheStatistics {
        var result: CacheStatistics = CacheStatistics(
            totalPhrases: 0,
            cachedPhrases: 0,
            hitRate: 0.0,
            storageUsage: 0,
            lastUpdated: nil
        )
        
        assessmentQueue.sync {
            result = self.cacheStatistics
        }
        
        return result
    }
    
    // MARK: - Initialization
    
    init(
        connectivityManager: ConnectivityManager = ConnectivityManager(),
        vocabularyDatabase: VocabularyDatabase = VocabularyDatabase.shared,
        translationCache: TranslationCache = TranslationCache.shared,
        audioEngine: AudioEngine = AudioEngine()
    ) {
        self.connectivityManager = connectivityManager
        self.vocabularyDatabase = vocabularyDatabase
        self.translationCache = translationCache
        self.audioEngine = audioEngine
        
        setupInitialAssessment()
    }
    
    // MARK: - Public Methods
    
    /// Check if translation is available offline
    func canTranslatePhrase(_ phrase: String, direction: TranslationEngine.TranslationDirection) -> Bool {
        let cacheKey = generateCacheKey(phrase: phrase, direction: direction)
        
        return cacheQueue.sync {
            return self.translationCache.getCachedTranslation(text: phrase, direction: direction) != nil
        }
    }
    
    /// Get cached translation if available
    func getCachedTranslation(
        text: String,
        direction: TranslationEngine.TranslationDirection
    ) -> String? {
        let cacheKey = generateCacheKey(text: text, direction: direction)
        
        return cacheQueue.sync {
            if let cached = self.translationCache.getCachedTranslation(text: text, direction: direction) {
                return cached.translatedText
            }
            return nil
        }
    }
    
    /// Cache translation result
    func cacheTranslation(
        text: String,
        translatedText: String,
        direction: TranslationEngine.TranslationDirection,
        confidence: Double = 0.8
    ) {
        cacheQueue.async {
            self.translationCache.cacheTranslation(
                text: text,
                translatedText: translatedText,
                direction: direction,
                confidence: confidence
            )
            self.updateCacheStatistics()
        }
    }
    
    /// Get translation with offline fallback
    func getTranslation(
        text: String,
        direction: TranslationEngine.TranslationDirection,
        completion: @escaping (Result<String, TranslationEngine.TranslationError>) -> Void
    ) {
        // First try cache
        if let cached = getCachedTranslation(text: text, direction: direction) {
            completion(.success(cached))
            return
        }
        
        // Check connectivity
        if connectivityManager.status == .online {
            // Online - try real translation
            performOnlineTranslation(text: text, direction: direction, completion: completion)
        } else {
            // Offline - provide fallback
            provideOfflineFallback(text: text, direction: direction, completion: completion)
        }
    }
    
    /// Assess offline capabilities
    func assessCapabilities() -> CapabilityAssessment {
        assessmentQueue.sync {
            return self.capabilityAssessment
        }
    }
    
    /// Get cache statistics
    func getCacheStatistics() -> CacheStatistics {
        assessmentQueue.sync {
            return self.cacheStatistics
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialAssessment() {
        assessmentQueue.async {
            self.updateCapabilityAssessment()
            self.updateCacheStatistics()
        }
    }
    
    private func updateCapabilityAssessment() {
        let totalPhrases = self.vocabularyDatabase.getTotalPhraseCount()
        let cachedPhrases = self.translationCache.getCachedPhrasesCount()
        let coverage = totalPhrases > 0 ? Double(cachedPhrases) / Double(totalPhrases) : 0.0
        
        let status: OfflineStatus
        let confidence: Double
        let limitations: [String]
        
        if cachedPhrases == 0 {
            status = .unknown
            confidence = 0.0
            limitations = ["No cached translations available"]
        } else if coverage < 0.3 {
            status = .limited
            confidence = coverage * 0.5
            limitations = ["Low coverage (<30%)", "Limited functionality"]
        } else if coverage < 0.7 {
            status = .degraded
            confidence = coverage * 0.7
            limitations = ["Partial coverage (30-70%)", "Some features may be limited"]
        } else {
            status = .offline
            confidence = coverage * 0.9
            limitations = ["High coverage (>70%)", "Most features available"]
        }
        
        self.capabilityAssessment = CapabilityAssessment(
            status: status,
            availablePhrases: cachedPhrases,
            coveragePercentage: coverage * 100,
            confidence: confidence,
            limitations: limitations
        )
    }
    
    private func updateCacheStatistics() {
        let totalPhrases = self.vocabularyDatabase.getTotalPhraseCount()
        let cachedPhrases = self.translationCache.getCachedPhrasesCount()
        let hitRate = cachedPhrases > 0 ? Double(cachedPhrases) / Double(totalPhrases) : 0.0
        let storageUsage = cachedPhrases * 200 / 1024 // Rough estimate: 200 bytes per entry
        
        self.cacheStatistics = CacheStatistics(
            totalPhrases: totalPhrases,
            cachedPhrases: cachedPhrases,
            hitRate: hitRate,
            storageUsage: storageUsage,
            lastUpdated: Date()
        )
    }
    
    private func performOnlineTranslation(
        text: String,
        direction: TranslationEngine.TranslationDirection,
        completion: @escaping (Result<String, TranslationEngine.TranslationError>) -> Void
    ) {
        // This would call the real translation engine
        // For now, we'll simulate success
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            completion(.success("Translated: \(text)"))
        }
    }
    
    private func provideOfflineFallback(
        text: String,
        direction: TranslationEngine.TranslationDirection,
        completion: @escaping (Result<String, TranslationEngine.TranslationError>) -> Void
    ) {
        // Provide simple fallback translation
        let fallbackTranslation = "Offline: \(text)"
        completion(.success(fallbackTranslation))
    }
    
    private func generateCacheKey(phrase: String, direction: TranslationEngine.TranslationDirection) -> String {
        let normalizedPhrase = phrase
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return "\(normalizedPhrase)_\(direction)"
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached translations
    func clearCache() {
        cacheQueue.async {
            // This would clear the cache - for now we'll just log
            print("Cache cleared")
            self.updateCacheStatistics()
        }
    }
    
    /// Evict old cache entries
    func evictOldEntries(maxEntries: Int = 10000) {
        cacheQueue.async {
            // This would evict old entries - for now we'll just log
            print("Evicting old cache entries")
            self.updateCacheStatistics()
        }
    }
    
    /// Get most frequently translated phrases
    func getMostFrequentPhrases(count: Int = 10) -> [(phrase: String, direction: TranslationEngine.TranslationDirection, confidence: Double)] {
        // This would return actual frequent phrases - for now we'll return mock data
        return (0..<count).map { index in
            return (
                phrase: "Phrase \(index)",
                direction: .humanToDog,
                confidence: Double(index) / Double(count)
            )
        }
    }
}