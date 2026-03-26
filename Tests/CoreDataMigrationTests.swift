import XCTest
import CoreData
@testable import WoofTalk

class CoreDataMigrationTests: XCTestCase {
    var oldStoreURL: URL!
    var oldModel: NSManagedObjectModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Prepare an old model (without Translation entity)
        let currentModel = PersistenceController.shared.container.managedObjectModel
        // Create old model by filtering out Translation entity
        let entities = currentModel.entities.filter { $0.name != "Translation" }
        oldModel = NSManagedObjectModel()
        oldModel.entities = entities

        // Create a temporary store using old model
        oldStoreURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("oldStore.sqlite")
        // Remove if exists from previous run
        try? FileManager.default.removeItem(at: oldStoreURL)

        let oldCoordinator = NSPersistentStoreCoordinator(managedObjectModel: oldModel)
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        try oldCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: oldStoreURL,
            options: options
        )
        let oldContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        oldContext.persistentStoreCoordinator = oldCoordinator

        // Save a dummy Item to ensure store is initialized
        let item = NSEntityDescription.insertNewObject(forEntityName: "Item", into: oldContext)
        item.setValue(Date(), forKey: "timestamp")
        try oldContext.save()
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: oldStoreURL)
        try super.tearDownWithError()
    }

    func testMigrationFromOldStore() throws {
        // Load a new container using the current model (which includes Translation)
        // but pointing to the old store URL. This should trigger a lightweight migration.
        let newContainer = NSPersistentContainer(name: "WoofTalk", managedObjectModel: PersistenceController.shared.container.managedObjectModel)
        let description = NSPersistentStoreDescription(url: oldStoreURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        newContainer.persistentStoreDescriptions = [description]

        var loadError: Error?
        newContainer.loadPersistentStores { _, error in
            loadError = error
        }
        XCTAssertNil(loadError, "Migration should succeed without error")

        // After migration, the Translation entity should be accessible
        let context = newContainer.viewContext
        let fetchRequest: NSFetchRequest<Translation> = Translation.fetchRequest()
        let results = try context.fetch(fetchRequest)
        // Initially there should be no Translation records
        XCTAssertEqual(results.count, 0)

        // Now insert a Translation record and save
        let translation = Translation(context: context)
        translation.originalText = "test input"
        translation.translatedText = "test output"
        translation.modeUsed = "ai"
        translation.qualityScore = 0.9
        translation.modelVersion = "1.0.0"
        translation.inferenceTime = 0.12
        translation.timestamp = Date()
        translation.id = UUID()
        try context.save()

        // Verify it was saved
        let saved = try context.fetch(fetchRequest)
        XCTAssertEqual(saved.count, 1)
        let savedTranslation = saved.first!
        XCTAssertEqual(savedTranslation.originalText, "test input")
        XCTAssertEqual(savedTranslation.translatedText, "test output")
        XCTAssertEqual(savedTranslation.modeUsed, "ai")
        XCTAssertEqual(savedTranslation.qualityScore, 0.9)
        XCTAssertEqual(savedTranslation.modelVersion, "1.0.0")
        XCTAssertEqual(savedTranslation.inferenceTime, 0.12)
    }

    func testSaveAndFetchTranslation() throws {
        // Use the shared PersistenceController to save and fetch
        try PersistenceController.shared.saveTranslation(
            original: "hello",
            translated: "woof woof",
            mode: "ai",
            qualityScore: 0.85,
            modelVersion: "1.0.0",
            inferenceTime: 0.3,
            timestamp: Date()
        )

        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Translation> = Translation.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)
        let translation = results.first!
        XCTAssertEqual(translation.originalText, "hello")
        XCTAssertEqual(translation.translatedText, "woof woof")
        XCTAssertEqual(translation.modeUsed, "ai")
        XCTAssertEqual(translation.qualityScore, 0.85)
        XCTAssertEqual(translation.modelVersion, "1.0.0")
        XCTAssertEqual(translation.inferenceTime, 0.3)
    }
}
