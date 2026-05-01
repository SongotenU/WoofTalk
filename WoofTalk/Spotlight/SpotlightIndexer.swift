import CoreSpotlight
import UniformTypeIdentifiers

struct SpotlightIndexer {
    static let shared = SpotlightIndexer()

    private let domainIdentifier = "com.wooftalk.translation"

    func indexTranslation(_ translation: RecentTranslation) {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
        attributeSet.title = translation.humanText
        attributeSet.contentDescription = translation.dogTranslation
        attributeSet.keywords = [translation.humanText, translation.dogTranslation, "dog", "translation", "woof"]
        attributeSet.lastUsedDate = translation.timestamp

        let item = CSSearchableItem(
            uniqueIdentifier: "\(translation.timestamp.timeIntervalSince1970)",
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                print("[Spotlight] Indexing error: \(error)")
            }
        }
    }

    func indexTranslations(_ translations: [RecentTranslation]) {
        let items = translations.map { translation -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
            attributeSet.title = translation.humanText
            attributeSet.contentDescription = translation.dogTranslation
            attributeSet.keywords = [translation.humanText, translation.dogTranslation, "dog", "translation"]
            attributeSet.lastUsedDate = translation.timestamp

            return CSSearchableItem(
                uniqueIdentifier: "\(translation.timestamp.timeIntervalSince1970)",
                domainIdentifier: domainIdentifier,
                attributeSet: attributeSet
            )
        }

        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("[Spotlight] Bulk indexing error: \(error)")
            }
        }
    }

    func deleteIndexedTranslation(_ timestamp: TimeInterval) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["\(timestamp)"]) { error in
            if let error = error {
                print("[Spotlight] Deletion error: \(error)")
            }
        }
    }

    func clearAllIndexedTranslations() {
        CSSearchableIndex.default().deleteAllSearchableItems { error in
            if let error = error {
                print("[Spotlight] Clear all error: \(error)")
            }
        }
    }
}
