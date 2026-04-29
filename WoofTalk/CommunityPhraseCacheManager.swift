// MARK: - CommunityPhraseCacheManager

import Foundation
import CoreData

/// Manages caching of community phrases for offline access
final class CommunityPhraseCacheManager {

    static let shared = CommunityPhraseCacheManager()

    private let cacheValidityDuration: TimeInterval = 3600 * 24
    private let cacheCountKey = "communityPhrasesCacheCount"
    private let cacheTimeKey = "communityPhrasesCacheTime"

    private var viewContext: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }

    private init() {}

    // MARK: - Cache Operations

    func cachePhrases(_ phrases: [CommunityPhrase]) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimeKey)
        UserDefaults.standard.set(phrases.count, forKey: cacheCountKey)
    }

    func getCachedPhrases(
        searchQuery: String? = nil,
        minQuality: Double? = nil,
        sortBy: SortOption = .quality,
        offset: Int = 0,
        limit: Int = 20
    ) -> [CommunityPhrase] {
        return CommunityPhraseSearchService.shared.getPhrases(
            searchQuery: searchQuery,
            minQuality: minQuality,
            sortBy: sortBy,
            offset: offset,
            limit: limit
        )
    }

    func isCacheValid() -> Bool {
        let lastCacheTime = UserDefaults.standard.double(forKey: cacheTimeKey)
        guard lastCacheTime > 0 else { return false }

        let cacheAge = Date().timeIntervalSince1970 - lastCacheTime
        return cacheAge < cacheValidityDuration
    }

    func invalidateCache() {
        UserDefaults.standard.removeObject(forKey: cacheTimeKey)
        UserDefaults.standard.removeObject(forKey: cacheCountKey)
    }

    func syncWithCloud(completion: @escaping (Result<Int, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            let phrases = CommunityPhrase.getAllSortedByQuality(context: self.viewContext)
            self.cachePhrases(phrases)
            completion(.success(phrases.count))
        }
    }

    func getCacheStats() -> (count: Int, age: TimeInterval?) {
        let count = UserDefaults.standard.integer(forKey: cacheCountKey)
        let lastCacheTime = UserDefaults.standard.double(forKey: cacheTimeKey)
        let age = lastCacheTime > 0 ? Date().timeIntervalSince1970 - lastCacheTime : nil
        return (count, age)
    }
}
