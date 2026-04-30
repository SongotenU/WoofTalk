import Foundation
import CoreData

/// Stores user corrections to improve future translations
final class TranslationFeedbackManager {

    static let shared = TranslationFeedbackManager()

    private let persistence = PersistenceController.shared
    private let queue = DispatchQueue(label: "com.wooftalk.feedback", qos: .utility)

    private init() {}

    // MARK: - Store Correction

    func storeCorrection(
        originalInput: String,
        originalTranslation: String,
        correctedTranslation: String,
        direction: String,
        confidence: Double
    ) {
        queue.async {
            // Use a background context for thread-safe Core Data operations
            let context = self.persistence.container.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            let correction = TranslationCorrection(context: context)
            correction.id = UUID()
            correction.originalInput = originalInput
            correction.originalTranslation = originalTranslation
            correction.correctedTranslation = correctedTranslation
            correction.direction = direction
            correction.confidence = confidence
            correction.timestamp = Date()
            correction.usedInTraining = false

            do {
                try context.save()
            } catch {
                print("Failed to save translation correction: \(error)")
            }
        }
    }

    // MARK: - Retrieve Corrections

    func getCorrections(for direction: String? = nil) -> [TranslationCorrection] {
        // viewContext is main-threaded, and this is a synchronous call expected to be on main thread
        let context = persistence.container.viewContext
        let request: NSFetchRequest<TranslationCorrection> = TranslationCorrection.fetchRequest()

        if let direction = direction {
            request.predicate = NSPredicate(format: "direction == %@", direction)
        }
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch corrections: \(error)")
            return []
        }
    }

    func getCorrectionCount() -> Int {
        let context = persistence.container.viewContext
        let request: NSFetchRequest<TranslationCorrection> = TranslationCorrection.fetchRequest()
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }

    // MARK: - Apply Corrections to Translation

    func applyCorrection(to input: String, direction: String) -> String? {
        let corrections = getCorrections(for: direction)
        // Find exact match first
        if let exact = corrections.first(where: { $0.originalInput?.lowercased() == input.lowercased() }) {
            return exact.correctedTranslation
        }
        return nil
    }
}
