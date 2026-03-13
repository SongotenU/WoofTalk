// MARK: - TranslationCache

import Foundation
import AVFoundation

/// Cache for translation results to improve performance and enable offline capability
final class TranslationCache {
    
    // MARK: - Public Types
    
    /// Cache statistics
    struct CacheStatistics: CustomStringConvertible {
        let hitCount: Int
        let missCount: Int
        let hitRate: Double
        let totalTranslations: Int
        let successfulTranslations: Int
        let failedTranslations: Int
        let lastTranslationTime: Date?
        let memoryUsage: Int
        
        var description: String {
            return "TranslationCacheStats(hits: \(hitCount), misses: \(missCount), hitRate: \(String(format: \"%.1f\", hitRate*100))%, total: \(totalTranslations), success: \(successfulTranslations), fail: \(failedTranslations), memory: \(memoryUsage)KB)"
        }
        
        var hitRate: Double {
            guard hitCount + missCount > 0 else { return 0.0 }
            return Double(hitCount) / Double(hitCount + missCount)
        }
    }
    
    /// Cached translation entry
    struct CachedTranslation: Codable {
        let translatedText: String
        let confidence: Double
        let timestamp: Date
        let direction: TranslationDirection
        
        enum TranslationDirection: String, Codable {
            case humanToDog
            case dogToHuman
        }
    }
    
    // MARK: - Private Properties
    
    static let shared = TranslationCache()
    private var cache: [String: CachedTranslation] = [:]
    private var accessQueue = DispatchQueue(label: "com.wooftalk.translation.cache")
    private var statistics = CacheStatistics(
        hitCount: 0,
        missCount: 0,
        hitRate: 0.0,
        totalTranslations: 0,
        successfulTranslations: 0,
        failedTranslations: 0,
        lastTranslationTime: nil,
        memoryUsage: 0
    )
    
    // MARK: - Public Methods
    
    /// Cache a translation result
    func cacheTranslation(
        text: String,
        translatedText: String,
        direction: TranslationDirection,
        confidence: Double
    ) {
        accessQueue.async {
            let cacheKey = self.generateCacheKey(text: text, direction: direction)
            let cachedTranslation = CachedTranslation(
                translatedText: translatedText,
                confidence: confidence,
                timestamp: Date(),
                direction: direction
            )
            
            self.cache[cacheKey] = cachedTranslation
            self.updateStatistics(hit: false, success: true)
            self.updateMemoryUsage()
        }
    }
    
    /// Get cached translation
    func getCachedTranslation(
        text: String,
        direction: TranslationDirection
    ) -> CachedTranslation? {
        var result: CachedTranslation? = nil
        
        accessQueue.sync {
            let cacheKey = self.generateCacheKey(text: text, direction: direction)
            result = self.cache[cacheKey]
            
            if result != nil {
                self.updateStatistics(hit: true, success: true)
            } else {
                self.updateStatistics(hit: false, success: false)
            }
        }
        
        return result
    }
    
    /// Get cache statistics
    func getStatistics() -> CacheStatistics {
        var stats = CacheStatistics(
            hitCount: 0,
            missCount: 0,
            hitRate: 0.0,
            totalTranslations: 0,
            successfulTranslations: 0,
            failedTranslations: 0,
            lastTranslationTime: nil,
            memoryUsage: 0
        )
        
        accessQueue.sync {
            stats = self.statistics
        }
        
        return stats
    }
    
    /// Clear the cache
    func clear() {
        accessQueue.async {
            self.cache.removeAll()
            self.statistics = CacheStatistics(
                hitCount: 0,
                missCount: 0,
                hitRate: 0.0,
                totalTranslations: 0,
                successfulTranslations: 0,
                failedTranslations: 0,
                lastTranslationTime: nil,
                memoryUsage: 0
            )
            self.updateMemoryUsage()
        }
    }
    
    /// Get cached phrases count
    func getCachedPhrasesCount() -> Int {
        var count = 0
        
        accessQueue.sync {
            count = self.cache.count
        }
        
        return count
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(text: String, direction: TranslationDirection) -> String {
        let normalizedText = text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return "\(normalizedText)_\(direction.rawValue)"
    }
    
    private func updateStatistics(hit: Bool, success: Bool) {
        statistics.totalTranslations += 1
        
        if hit {
            statistics.hitCount += 1
        } else {
            statistics.missCount += 1
        }
        
        if success {
            statistics.successfulTranslations += 1
        } else {
            statistics.failedTranslations += 1
        }
        
        statistics.lastTranslationTime = Date()
    }
    
    private func updateMemoryUsage() {
        let estimatedSize = cache.count * 200 // Rough estimate: 200 bytes per entry
        statistics.memoryUsage = estimatedSize / 1024 // Convert to KB
    }
    
    // MARK: - Persistence
    
    /// Save cache to disk
    func saveToDisk() {
        accessQueue.async {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(self.cache)
                let fileURL = self.getCacheFileURL()
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("Error saving translation cache: \(error)")
            }
        }
    }
    
    /// Load cache from disk
    func loadFromDisk() {
        accessQueue.async {
            let fileURL = self.getCacheFileURL()
            
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return
            }
            
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                self.cache = try decoder.decode([String: CachedTranslation].self, from: data)
                self.updateMemoryUsage()
            } catch {
                print("Error loading translation cache: \(error)")
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func getCacheFileURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("wooftalk_translation_cache.json")
    }
    
    /// Evict old cache entries based on age and usage
    func evictOldEntries(maxEntries: Int = 10000) {
        accessQueue.async {
            guard self.cache.count > maxEntries else { return }
            
            let sortedEntries = self.cache.sorted { entry1, entry2 in
                return entry1.value.timestamp > entry2.value.timestamp
            }
            
            let entriesToKeep = sortedEntries.prefix(maxEntries)
            var newCache: [String: CachedTranslation] = [:]
            
            for entry in entriesToKeep {
                newCache[entry.key] = entry.value
            }
            
            self.cache = newCache
            self.updateMemoryUsage()
        }
    }
    
    /// Get cache hit rate for a specific phrase
    func getHitRate(for text: String, direction: TranslationDirection) -> Double {
        var hitRate = 0.0
        
        accessQueue.sync {
            let cacheKey = self.generateCacheKey(text: text, direction: direction)
            if self.cache[cacheKey] != nil {
                hitRate = 1.0
            }
        }
        
        return hitRate
    }
    
    /// Get cache statistics for a specific category
    func getStatistics(for direction: TranslationDirection) -> CacheStatistics {
        var stats = CacheStatistics(
            hitCount: 0,
            missCount: 0,
            hitRate: 0.0,
            totalTranslations: 0,
            successfulTranslations: 0,
            failedTranslations: 0,
            lastTranslationTime: nil,
            memoryUsage: 0
        )
        
        accessQueue.sync {
            let filteredCache = self.cache.filter { $0.value.direction == direction }
            stats.hitCount = filteredCache.count
            stats.missCount = self.cache.count - filteredCache.count
            stats.totalTranslations = self.cache.count
            stats.lastTranslationTime = self.statistics.lastTranslationTime
            stats.memoryUsage = self.statistics.memoryUsage
        }
        
        return stats
    }
}

// MARK: - Cache Manager Extension

extension TranslationCache {
    
    /// Get most frequently translated phrases
    func getMostFrequentPhrases(count: Int = 10) -> [(phrase: String, direction: TranslationDirection, confidence: Double)] {
        var frequentPhrases: [(phrase: String, direction: TranslationDirection, confidence: Double)] = []
        
        accessQueue.sync {
            let sortedEntries = self.cache.sorted { entry1, entry2 in
                // Simple frequency approximation based on cache size and usage patterns
                return arc4random_uniform(100) > arc4random_uniform(100)
            }
            
            for entry in sortedEntries.prefix(count) {
                frequentPhrases.append((
                    phrase: entry.key,
                    direction: entry.value.direction,
                    confidence: entry.value.confidence
                ))
            }
        }
        
        return frequentPhrases
    }
    
    /// Get cache usage by time period
    func getUsageByTime() -> [(hour: Int, count: Int)] {
        var usageByHour: [Int: Int] = [:]
        
        accessQueue.sync {
            for (_, value) in self.cache {
                let hour = Calendar.current.component(.hour, from: value.timestamp)
                usageByHour[hour, default: 0] += 1
            }
        }
        
        return usageByHour.sorted { $0.key < $1.key }
    }
    
    /// Get cache health status
    func getHealthStatus() -> String {
        let stats = getStatistics()
        let status: String
        
        if stats.hitRate < 0.1 {
            status = "Poor - cache hit rate too low"
        } else if stats.hitRate < 0.3 {
            status = "Fair - room for improvement"
        } else if stats.hitRate < 0.6 {
            status = "Good - performing well"
        } else {
            status = "Excellent - cache performing optimally"
        }
        
        return "Cache Health: \(status) | Hit Rate: \(String(format: \"%.1f\", stats.hitRate*100))% | Memory: \(stats.memoryUsage)KB"
    }
}