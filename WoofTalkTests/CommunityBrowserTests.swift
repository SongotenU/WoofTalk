import XCTest
@testable import WoofTalk

final class CommunityBrowserTests: XCTestCase {
    
    var cacheManager: CommunityPhraseCacheManager!
    
    override func setUp() {
        super.setUp()
        cacheManager = CommunityPhraseCacheManager.shared
    }
    
    override func tearDown() {
        cacheManager = nil
        super.tearDown()
    }
    
    func testCacheValidityCheck() {
        XCTAssertFalse(cacheManager.isCacheValid())
    }
    
    func testCacheStatsReturnsValidTuple() {
        let stats = cacheManager.getCacheStats()
        XCTAssertEqual(stats.count, 0)
        XCTAssertNil(stats.age)
    }
    
    func testSearchServiceSearchDebounced() {
        let searchService = CommunityPhraseSearchService.shared
        searchService.searchDebounced(query: "test")
    }
    
    func testSearchServiceWithEmptyQuery() {
        let searchService = CommunityPhraseSearchService.shared
        let results = searchService.search(query: "")
        XCTAssertNotNil(results)
    }
    
    func testSearchServiceWithShortQuery() {
        let searchService = CommunityPhraseSearchService.shared
        let results = searchService.search(query: "a")
        XCTAssertNotNil(results)
    }
    
    func testQualityTierFromScore() {
        let excellentPhrase = createMockPhrase(quality: 0.95)
        let goodPhrase = createMockPhrase(quality: 0.75)
        let fairPhrase = createMockPhrase(quality: 0.55)
        let poorPhrase = createMockPhrase(quality: 0.35)
        
        XCTAssertEqual(excellentPhrase.qualityTier, .excellent)
        XCTAssertEqual(goodPhrase.qualityTier, .good)
        XCTAssertEqual(fairPhrase.qualityTier, .fair)
        XCTAssertEqual(poorPhrase.qualityTier, .poor)
    }
    
    func testQualityScoreFormatted() {
        let phrase = createMockPhrase(quality: 0.85)
        XCTAssertEqual(phrase.qualityScoreFormatted, "85%")
    }
    
    func testRelevanceScoreCalculation() {
        let phrase = createMockPhrase(quality: 0.8)
        phrase.humanText = "Hello world"
        
        let exactMatchScore = phrase.relevanceScore(for: "Hello world")
        let prefixMatchScore = phrase.relevanceScore(for: "Hello")
        let containsMatchScore = phrase.relevanceScore(for: "world")
        let noMatchScore = phrase.relevanceScore(for: "xyz")
        
        XCTAssertGreaterThan(exactMatchScore, prefixMatchScore)
        XCTAssertGreaterThan(prefixMatchScore, containsMatchScore)
        XCTAssertGreaterThan(containsMatchScore, noMatchScore)
    }
    
    func testOfflineAccessWithoutNetwork() {
        let phrases = cacheManager.getCachedPhrases()
        XCTAssertNotNil(phrases)
        XCTAssertEqual(phrases.count, 0)
    }
    
    func testPaginationParameters() {
        let page1 = cacheManager.getCachedPhrases(offset: 0, limit: 20)
        let page2 = cacheManager.getCachedPhrases(offset: 20, limit: 20)
        XCTAssertNotNil(page1)
        XCTAssertNotNil(page2)
    }
    
    private func createMockPhrase(quality: Double) -> CommunityPhrase {
        let phrase = CommunityPhrase(context: PersistenceController.preview.container.viewContext)
        phrase.qualityScore = quality
        phrase.humanText = "Test phrase"
        phrase.dogTranslation = "Test translation"
        phrase.timestamp = Date()
        return phrase
    }
}
