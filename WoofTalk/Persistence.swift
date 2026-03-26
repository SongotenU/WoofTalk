//
//  Persistence.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try result.container.viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WoofTalk")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        // Enable automatic migration for lightweight migrations
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Save a translation record with AI metadata
    func saveTranslation(
        original: String,
        translated: String,
        mode: String?,
        qualityScore: Double,
        modelVersion: String?,
        inferenceTime: Double,
        timestamp: Date = Date()
    ) throws {
        let context = container.viewContext
        let translation = Translation(context: context)
        translation.originalText = original
        translation.translatedText = translated
        translation.modeUsed = mode
        translation.qualityScore = qualityScore
        translation.modelVersion = modelVersion
        translation.inferenceTime = inferenceTime
        translation.timestamp = timestamp
        translation.id = UUID()
        try context.save()
    }
}
