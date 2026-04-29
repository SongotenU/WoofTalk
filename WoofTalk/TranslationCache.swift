import Foundation

/// Cache for translation results to improve performance and enable offline capability
final class TranslationCache {

    struct CachedTranslation: Codable {
        let translatedText: String
        let confidence: Double
        let timestamp: Date
        let direction: TranslationDirection
    }

    struct CacheStatistics {
        let hitCount: Int
        let missCount: Int
        var hitRate: Double {
            guard hitCount + missCount > 0 else { return 0.0 }
            return Double(hitCount) / Double(hitCount + missCount)
        }
    }

    static let shared = TranslationCache()

    private var cache: [String: CachedTranslation] = [:]
    private var hitCount = 0
    private var missCount = 0
    private let accessQueue = DispatchQueue(label: "com.wooftalk.translation.cache")

    func cacheTranslation(text: String, translatedText: String, direction: TranslationDirection, confidence: Double) {
        accessQueue.async {
            self.cache[self.cacheKey(text: text, direction: direction)] = CachedTranslation(
                translatedText: translatedText, confidence: confidence, timestamp: Date(), direction: direction
            )
        }
    }

    func getCachedTranslation(text: String, direction: TranslationDirection) -> CachedTranslation? {
        accessQueue.sync {
            let key = cacheKey(text: text, direction: direction)
            if cache[key] != nil { hitCount += 1 } else { missCount += 1 }
            return cache[key]
        }
    }

    func getStatistics() -> CacheStatistics {
        accessQueue.sync { CacheStatistics(hitCount: hitCount, missCount: missCount) }
    }

    func clear() {
        accessQueue.async {
            self.cache.removeAll()
            self.hitCount = 0
            self.missCount = 0
        }
    }

    /// Get cached phrases count
    func getCachedPhrasesCount() -> Int {
        var count = 0
        accessQueue.sync { count = self.cache.count }
        return count
    }

    // MARK: - Persistence

    func saveToDisk() {
        accessQueue.async {
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(self.cache)
                let fileURL = self.cacheFileURL()
                try data.write(to: fileURL, options: .atomic)
            } catch {
                os_log("Error saving cache: %@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        }
    }

    func loadFromDisk() {
        accessQueue.async {
            let fileURL = self.cacheFileURL()
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                self.cache = try decoder.decode([String: CachedTranslation].self, from: data)
            } catch {
                os_log("Error loading cache: %@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        }
    }

    // MARK: - Private

    private func cacheKey(text: String, direction: TranslationDirection) -> String {
        "\(text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))_\(direction.rawValue)"
    }

    private func cacheFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("wooftalk_translation_cache.json")
    }
}
