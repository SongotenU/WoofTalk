// MARK: - CommunityPhraseSearchService

import Foundation
import CoreData
import Combine

final class CommunityPhraseSearchService {
    
    static let shared = CommunityPhraseSearchService()
    
    private let minQueryLength = 2
    private let debounceInterval: TimeInterval = 0.3
    
    private var searchCancellable: AnyCancellable?
    private let searchSubject = PassthroughSubject<String, Never>()
    
    private var viewContext: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
    
    private init() {
        setupDebounce()
    }
    
    private func setupDebounce() {
        searchCancellable = searchSubject
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
    }
    
    func searchDebounced(query: String) {
        searchSubject.send(query)
    }
    
    func search(query: String, minQuality: Double? = nil) -> [CommunityPhrase] {
        guard query.count >= minQueryLength else {
            return getAllPhrases(minQuality: minQuality)
        }
        return performSearch(query: query, minQuality: minQuality)
    }
    
    func getPhrases(
        searchQuery: String? = nil,
        minQuality: Double? = nil,
        sortBy: SortOption = .quality,
        offset: Int = 0,
        limit: Int = 20
    ) -> [CommunityPhrase] {
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        if let query = searchQuery, query.count >= minQueryLength {
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
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "qualityScore", ascending: false)]
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
            print("Error searching phrases: \(error)")
            return []
        }
    }
    
    private func getAllPhrases(minQuality: Double?) -> [CommunityPhrase] {
        return getPhrases(minQuality: minQuality, sortBy: .quality)
    }
    
    private func performSearch(query: String, minQuality: Double?) -> [CommunityPhrase] {
        return getPhrases(
            searchQuery: query,
            minQuality: minQuality,
            sortBy: query.isEmpty ? .quality : .relevance
        )
    }
}
