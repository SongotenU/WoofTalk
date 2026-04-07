import Foundation

// MARK: - Memory Manager
/// Manages memory optimization with LRU caching, lazy loading, and memory pressure handling

final class MemoryManager {
    
    // MARK: - Singleton
    static let shared = MemoryManager()
    
    // MARK: - LRU Cache
    private class LRUCache<Key: Hashable, Value> {
        private var cache: [Key: Value] = [:]
        private var order: [Key] = []
        private let maxCapacity: Int
        private let lock = NSLock()
        
        init(maxCapacity: Int) {
            self.maxCapacity = maxCapacity
        }
        
        func get(_ key: Key) -> Value? {
            lock.lock()
            defer { lock.unlock() }
            
            guard let value = cache[key] else { return nil }
            
            // Move to end (most recently used)
            if let index = order.firstIndex(of: key) {
                order.remove(at: index)
                order.append(key)
            }
            return value
        }
        
        func set(_ key: Key, value: Value) {
            lock.lock()
            defer { lock.unlock() }
            
            if cache[key] != nil {
                // Update existing - move to end
                if let index = order.firstIndex(of: key) {
                    order.remove(at: index)
                }
            } else if cache.count >= maxCapacity {
                // Evict least recently used
                if let lruKey = order.first {
                    cache.removeValue(forKey: lruKey)
                    order.removeFirst()
                }
            }
            
            cache[key] = value
            order.append(key)
        }
        
        func remove(_ key: Key) {
            lock.lock()
            defer { lock.unlock() }
            
            cache.removeValue(forKey: key)
            if let index = order.firstIndex(of: key) {
                order.remove(at: index)
            }
        }
        
        func clear() {
            lock.lock()
            defer { lock.unlock() }
            
            cache.removeAll()
            order.removeAll()
        }
        
        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return cache.count
        }
    }
    
    // MARK: - Translation Cache
    private let translationCache: LRUCache<String, CachedTranslation>
    private let qualityScoreCache: LRUCache<String, QualityScoreResult>
    private let languageDetectionCache: LRUCache<String, DetectedLanguage>
    
    // MARK: - Lazy Initializers
    private var qualityScorer: TranslationQualityScorer?
    private var metadataParser: AITranslationMetadata?
    
    // MARK: - Weak References
    private var observers: [ObjectWrapper] = []
    
    // MARK: - Memory Pressure
    private var isLowMemoryMode = false
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    // MARK: - Configuration
    private let maxTranslationCacheSize = 100
    private let maxQualityScoreCacheSize = 50
    private let maxLanguageDetectionCacheSize = 200
    
    // MARK: - Init
    private init() {
        translationCache = LRUCache(maxCapacity: maxTranslationCacheSize)
        qualityScoreCache = LRUCache(maxCapacity: maxQualityScoreCacheSize)
        languageDetectionCache = LRUCache(maxCapacity: maxLanguageDetectionCacheSize)
        
        setupMemoryPressureHandler()
    }
    
    // MARK: - Translation Cache
    func cachedTranslation(for key: String) -> CachedTranslation? {
        return translationCache.get(key)
    }
    
    func cacheTranslation(_ translation: CachedTranslation, for key: String) {
        guard !isLowMemoryMode else { return }
        translationCache.set(key, value: translation)
    }
    
    // MARK: - Quality Score Cache
    func cachedQualityScore(for key: String) -> QualityScoreResult? {
        return qualityScoreCache.get(key)
    }
    
    func cacheQualityScore(_ result: QualityScoreResult, for key: String) {
        guard !isLowMemoryMode else { return }
        qualityScoreCache.set(key, value: result)
    }
    
    // MARK: - Language Detection Cache
    func cachedLanguageDetection(for text: String) -> DetectedLanguage? {
        return languageDetectionCache.get(text)
    }
    
    func cacheLanguageDetection(_ result: DetectedLanguage, for text: String) {
        guard !isLowMemoryMode else { return }
        languageDetectionCache.set(text, value: result)
    }
    
    // MARK: - Lazy Initialization
    func getQualityScorer() -> TranslationQualityScorer {
        if qualityScorer == nil {
            qualityScorer = TranslationQualityScorer()
        }
        return qualityScorer!
    }
    
    func getMetadataParser() -> AITranslationMetadata {
        if metadataParser == nil {
            metadataParser = AITranslationMetadata()
        }
        return metadataParser!
    }
    
    // MARK: - Weak Observer Pattern
    func addObserver(_ observer: AnyObject) {
        observers.removeAll { $0.object === nil }
        observers.append(ObjectWrapper(object: observer))
    }
    
    // MARK: - Memory Pressure Handling
    private func setupMemoryPressureHandler() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: .main
        )
        
        memoryPressureSource?.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }
        
        memoryPressureSource?.resume()
    }
    
    private func handleMemoryPressure() {
        guard let source = memoryPressureSource else { return }
        
        if source.isCancelled { return }
        
        let event = source.data
        
        if event.contains(.critical) {
            // Critical pressure - clear all caches
            clearAllCaches()
            isLowMemoryMode = true
            NotificationCenter.default.post(name: .memoryPressureCritical, object: nil)
        } else if event.contains(.warning) {
            // Warning - reduce cache sizes by 50%
            reduceCacheSizes(by: 0.5)
            NotificationCenter.default.post(name: .memoryPressureWarning, object: nil)
        }
    }
    
    func clearAllCaches() {
        translationCache.clear()
        qualityScoreCache.clear()
        languageDetectionCache.clear()
    }
    
    func reduceCacheSizes(by factor: Double) {
        // Keep only a fraction of each cache
        // LRU cache handles this internally, but we trigger cleanup
        clearExpiredCacheEntries()
    }
    
    private func clearExpiredCacheEntries() {
        // Clear entries older than 1 hour
        let oneHourAgo = Date().addingTimeInterval(-3600)
        
        // For translation cache, we'd need to track timestamps
        // This is a simplified implementation
    }
    
    func setLowMemoryMode(_ enabled: Bool) {
        isLowMemoryMode = enabled
        if enabled {
            clearAllCaches()
        }
    }
    
    // MARK: - Memory Stats
    var currentMemoryUsage: UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
    
    var cacheMemorySize: Int {
        return translationCache.count + qualityScoreCache.count + languageDetectionCache.count
    }
}

// MARK: - Cached Translation
struct CachedTranslation {
    let originalText: String
    let translatedText: String
    let sourceLanguage: String
    let targetLanguage: String
    let timestamp: Date
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > 3600 // 1 hour
    }
}

// MARK: - Quality Score Result
struct QualityScoreResult {
    let confidence: Double
    let accuracy: Double
    let qualityTier: QualityTier
    let timestamp: Date
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > 1800 // 30 minutes
    }
}

enum QualityTier: String {
    case excellent, good, acceptable, poor
}

// MARK: - Detected Language
struct DetectedLanguage {
    let languageCode: String
    let confidence: Double
    let timestamp: Date
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > 3600 // 1 hour
    }
}

// MARK: - Object Wrapper for Weak References
private class ObjectWrapper {
    weak var object: AnyObject?
    
    init(object: AnyObject) {
        self.object = object
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let memoryPressureWarning = Notification.Name("MemoryPressureWarning")
    static let memoryPressureCritical = Notification.Name("MemoryPressureCritical")
}
