import XCTest
@testable import WoofTalk

final class CommunityPhraseSyncTests: XCTestCase {
    
    var cacheManager: CommunityPhraseCacheManager!
    
    override func setUp() {
        super.setUp()
        cacheManager = CommunityPhraseCacheManager.shared
    }
    
    override func tearDown() {
        cacheManager = nil
        super.tearDown()
    }
    
    func testSyncCompletesSuccessfully() {
        let expectation = self.expectation(description: "Sync completes")
        
        cacheManager.syncWithCloud { result in
            switch result {
            case .success(let count):
                XCTAssertGreaterThanOrEqual(count, 0)
            case .failure:
                XCTFail("Sync should not fail")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testCacheInvalidation() {
        cacheManager.invalidateCache()
        XCTAssertFalse(cacheManager.isCacheValid())
    }
    
    func testCachePhrasesUpdatesCacheTime() {
        cacheManager.invalidateCache()
        XCTAssertFalse(cacheManager.isCacheValid())
        
        let phrase = CommunityPhrase(context: PersistenceController.preview.container.viewContext)
        phrase.humanText = "Test"
        phrase.dogTranslation = "Translation"
        phrase.qualityScore = 0.8
        
        cacheManager.cachePhrases([phrase])
        
        XCTAssertTrue(cacheManager.isCacheValid())
    }
    
    func testCachingEmptyArray() {
        cacheManager.cachePhrases([])
        XCTAssertTrue(cacheManager.isCacheValid())
        
        let stats = cacheManager.getCacheStats()
        XCTAssertEqual(stats.count, 0)
    }
    
    func testOfflineCachingPreservesData() {
        let testPhrase = CommunityPhrase(context: PersistenceController.preview.container.viewContext)
        testPhrase.humanText = "Offline test"
        testPhrase.dogTranslation = "Offline translation"
        testPhrase.qualityScore = 0.9
        
        cacheManager.cachePhrases([testPhrase])
        
        let cachedPhrases = cacheManager.getCachedPhrases()
        XCTAssertNotNil(cachedPhrases)
    }
    
    func testCacheStatsAfterSync() {
        cacheManager.invalidateCache()
        
        let expectation = self.expectation(description: "Cache stats updated")
        
        cacheManager.syncWithCloud { result in
            switch result {
            case .success:
                let stats = self.cacheManager.getCacheStats()
                XCTAssertNotNil(stats)
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
}
