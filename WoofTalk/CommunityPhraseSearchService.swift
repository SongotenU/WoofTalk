// MARK: - CommunityPhraseSearchService

import Foundation
import CoreData

final class CommunityPhraseSearchService {

    static let shared = CommunityPhraseSearchService()

    private let minQueryLength = 2

    private var viewContext: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }

    private init() {}

    func search(query: String, minQuality: Double? = nil) -> [CommunityPhrase] {
        guard query.count >= minQueryLength else {
            return getPhrases(minQuality: minQuality, sortBy: .quality)
        }
        return getPhrases(searchQuery: query, minQuality: minQuality, sortBy: .relevance)
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
            os_log("Error searching phrases: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
            return []
        }
    }
}
