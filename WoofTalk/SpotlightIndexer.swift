import CoreSpotlight
import MobileCoreServices

/// Manages Spotlight search indexing for past translations
final class SpotlightIndexer {
    static let shared = SpotlightIndexer()
    private let searchableIndex = CSSearchableIndex.default()

    private init() {}

    func indexTranslation(_ translation: TranslationItem) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = translation.displayText
        attributeSet.contentDescription = "Translation to \(translation.targetLanguage)"
        attributeSet.keywords = [translation.sourceText, translation.targetLanguage, "translation"]
        attributeSet.identifier = translation.id.uuidString

        let item = CSSearchableItem(
            uniqueIdentifier: translation.id.uuidString,
            domainIdentifier: "com.wooftalk.translations",
            attributeSet: attributeSet
        )

        searchableIndex.indexSearchableItems([item]) { error in
            if let error = error {
                print("Spotlight indexing error: \(error)")
            }
        }
    }

    func deleteTranslation(id: String) {
        searchableIndex.deleteSearchableItems(withIdentifiers: [id]) { error in
            if let error = error {
                print("Spotlight delete error: \(error)")
            }
        }
    }

    func clearAll() {
        searchableIndex.deleteAllSearchableItems { error in
            if let error = error {
                print("Spotlight clear error: \(error)")
            }
        }
    }
}

struct TranslationItem {
    let id: UUID
    let sourceText: String
    let displayText: String
    let targetLanguage: String
}
