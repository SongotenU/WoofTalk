import XCTest
import AVFoundation

// MARK: - MultiLanguageTests

final class MultiLanguageTests: XCTestCase {
    
    var routingService: LanguageRoutingService!
    var multiLanguageAdapter: MultiLanguageAdapter!
    var detectionManager: LanguageDetectionManager!
    
    override func setUp() {
        super.setUp()
        routingService = LanguageRoutingService.shared
        multiLanguageAdapter = MultiLanguageAdapter.shared
        detectionManager = LanguageDetectionManager.shared
    }
    
    override func tearDown() {
        routingService = nil
        multiLanguageAdapter = nil
        detectionManager = nil
        super.tearDown()
    }
    
    // MARK: - Language Support Tests
    
    func testDogLanguageIsSupported() {
        let isSupported = multiLanguageAdapter.isLanguageAvailable(.dog)
        XCTAssertTrue(isSupported, "Dog language should be supported")
    }
    
    func testCatLanguageIsSupported() {
        let isSupported = multiLanguageAdapter.isLanguageAvailable(.cat)
        XCTAssertTrue(isSupported, "Cat language should be supported")
    }
    
    func testBirdLanguageIsSupported() {
        let isSupported = multiLanguageAdapter.isLanguageAvailable(.bird)
        XCTAssertTrue(isSupported, "Bird language should be supported")
    }
    
    // MARK: - Translation Tests
    
    func testDogHumanToAnimalTranslation() async throws {
        let result = try await multiLanguageAdapter.translate(
            input: "hello",
            language: .dog,
            direction: .humanToAnimal(.dog)
        )
        
        XCTAssertFalse(result.translatedText.isEmpty)
        XCTAssertNotNil(result.languageUsed)
    }
    
    func testCatHumanToAnimalTranslation() async throws {
        let result = try await multiLanguageAdapter.translate(
            input: "hello",
            language: .cat,
            direction: .humanToAnimal(.cat)
        )
        
        XCTAssertFalse(result.translatedText.isEmpty)
    }
    
    func testBirdHumanToAnimalTranslation() async throws {
        let result = try await multiLanguageAdapter.translate(
            input: "hello",
            language: .bird,
            direction: .humanToAnimal(.bird)
        )
        
        XCTAssertFalse(result.translatedText.isEmpty)
    }
    
    func testDogAnimalToHumanTranslation() async throws {
        let result = try await multiLanguageAdapter.translate(
            input: "woof woof",
            language: .dog,
            direction: .animalToHuman(.dog)
        )
        
        XCTAssertFalse(result.translatedText.isEmpty)
    }
    
    func testCatAnimalToHumanTranslation() async throws {
        let result = try await multiLanguageAdapter.translate(
            input: "meow",
            language: .cat,
            direction: .animalToHuman(.cat)
        )
        
        XCTAssertFalse(result.translatedText.isEmpty)
    }
    
    func testBirdAnimalToHumanTranslation() async throws {
        let result = try await multiLanguageAdapter.translate(
            input: "chirp",
            language: .bird,
            direction: .animalToHuman(.bird)
        )
        
        XCTAssertFalse(result.translatedText.isEmpty)
    }
    
    // MARK: - Fallback Translation Tests
    
    func testDogFallbackTranslation() {
        let translation = multiLanguageAdapter.translateWithFallback(
            input: "unknown phrase",
            language: .dog,
            direction: .humanToAnimal(.dog)
        )
        
        XCTAssertFalse(translation.isEmpty)
    }
    
    func testCatFallbackTranslation() {
        let translation = multiLanguageAdapter.translateWithFallback(
            input: "unknown phrase",
            language: .cat,
            direction: .humanToAnimal(.cat)
        )
        
        XCTAssertFalse(translation.isEmpty)
    }
    
    func testBirdFallbackTranslation() {
        let translation = multiLanguageAdapter.translateWithFallback(
            input: "unknown phrase",
            language: .bird,
            direction: .humanToAnimal(.bird)
        )
        
        XCTAssertFalse(translation.isEmpty)
    }
    
    // MARK: - Language Detection Tests
    
    func testLanguageDetectionFromTextDog() {
        let result = detectionManager.detectLanguage(fromText: "woof woof bark")
        
        XCTAssertEqual(result.detectedLanguage, .dog)
        XCTAssertTrue(result.confidence > 0)
    }
    
    func testLanguageDetectionFromTextCat() {
        let result = detectionManager.detectLanguage(fromText: "meow meow purr")
        
        XCTAssertEqual(result.detectedLanguage, .cat)
        XCTAssertTrue(result.confidence > 0)
    }
    
    func testLanguageDetectionFromTextBird() {
        let result = detectionManager.detectLanguage(fromText: "chirp tweet warble")
        
        XCTAssertEqual(result.detectedLanguage, .bird)
        XCTAssertTrue(result.confidence > 0)
    }
    
    // MARK: - Routing Service Tests
    
    func testSetLanguage() {
        routingService.setLanguage(.cat)
        
        XCTAssertEqual(routingService.currentLanguage, .cat)
        
        routingService.setLanguage(.dog)
    }
    
    func testGetAvailableLanguages() {
        let languages = routingService.getAvailableLanguages()
        
        XCTAssertEqual(languages.count, 3)
        XCTAssertTrue(languages.contains { $0.language == .dog })
        XCTAssertTrue(languages.contains { $0.language == .cat })
        XCTAssertTrue(languages.contains { $0.language == .bird })
    }
    
    func testRoutingServiceTranslation() async throws {
        routingService.setLanguage(.dog)
        
        let result = try await routingService.translate(
            input: "hello",
            direction: .humanToAnimal(.dog)
        )
        
        XCTAssertFalse(result.translatedText.isEmpty)
    }
    
    // MARK: - Storage Tests
    
    func testLanguagePersistence() {
        let storage = LanguageStorageManager.shared
        
        storage.selectedLanguage = .cat
        XCTAssertEqual(storage.selectedLanguage, .cat)
        
        storage.selectedLanguage = .dog
        XCTAssertEqual(storage.selectedLanguage, .dog)
    }
    
    func testRecentLanguages() {
        let storage = LanguageStorageManager.shared
        
        storage.selectedLanguage = .bird
        storage.selectedLanguage = .cat
        storage.selectedLanguage = .dog
        
        let recent = storage.recentLanguages
        XCTAssertTrue(recent.contains(.dog))
    }
    
    // MARK: - Vocabulary Tests
    
    func testDogVocabularySize() {
        let pack = LanguagePackManager.shared.getPack(for: .dog)
        XCTAssertNotNil(pack)
        XCTAssertTrue(pack!.vocabularySize > 0)
    }
    
    func testCatVocabularySize() {
        let pack = LanguagePackManager.shared.getPack(for: .cat)
        XCTAssertNotNil(pack)
        XCTAssertTrue(pack!.vocabularySize > 0)
    }
    
    func testBirdVocabularySize() {
        let pack = LanguagePackManager.shared.getPack(for: .bird)
        XCTAssertNotNil(pack)
        XCTAssertTrue(pack!.vocabularySize > 0)
    }
}
