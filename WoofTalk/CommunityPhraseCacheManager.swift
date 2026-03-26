// MARK: - CommunityPhraseCacheManager

import Foundation
import CoreData

enum SortOption: String, CaseIterable {
    case quality = "Quality"
    case date = "Date"
    case relevance = "Relevance"
}

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
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        if let query = searchQuery, query.count >= 2 {
            predicates.append(NSPredicate(
                format: "humanText CONTAINS[cd] %@ OR dogTranslation CONTAINS[cd] %@",
                query, query
            ))
        }
        
        if let minQ = minQuality {
            predicates.append(NSPredicate(format: "qualityScore >= %lf", minQ))
        }
        
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        switch sortBy {
        case .quality:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "qualityScore", ascending: false)]
        case .date:
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        case .relevance:
            if let query = searchQuery {
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "qualityScore", ascending: false)]
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates.isEmpty ? [] : predicates)
            }
        }
        
        fetchRequest.fetchOffset = offset
        fetchRequest.fetchLimit = limit
        
        do {
            var results = try viewContext.fetch(fetchRequest)
            
            if sortBy == .relevance, let query = searchQuery {
                results.sort { $0.relevanceScore(for: query) > $1.relevanceScore(for: query) }
            }
            
            return results
        } catch {
            print("Error fetching cached phrases: \(error)")
            return []
        }
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
            guard let self = self else { return }
            
            do {
                let phrases = CommunityPhrase.getAllSortedByQuality(context: self.viewContext)
                self.cachePhrases(phrases)
                completion(.success(phrases.count))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func getCacheStats() -> (count: Int, age: TimeInterval?) {
        let count = UserDefaults.standard.integer(forKey: cacheCountKey)
        let lastCacheTime = UserDefaults.standard.double(forKey: cacheTimeKey)
        let age = lastCacheTime > 0 ? Date().timeIntervalSince1970 - lastCacheTime : nil
        return (count, age)
    }
}
