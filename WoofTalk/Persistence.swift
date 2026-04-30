import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    private(set) let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WoofTalk")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved error \(error as NSError)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveTranslation(
        original: String,
        translated: String,
        mode: String? = nil,
        qualityScore: Double,
        modelVersion: String? = nil,
        inferenceTime: Double,
        timestamp: Date = Date()
    ) throws {
        let translation = Translation(context: container.viewContext)
        translation.id = UUID()
        translation.originalText = original
        translation.translatedText = translated
        translation.modeUsed = mode
        translation.qualityScore = qualityScore
        translation.modelVersion = modelVersion
        translation.inferenceTime = inferenceTime
        translation.timestamp = timestamp
        try container.viewContext.save()
    }
}
