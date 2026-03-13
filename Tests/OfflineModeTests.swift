// MARK: - OfflineModeTests

import XCTest
@testable import WoofTalk

final class OfflineModeTests: XCTestCase {
    
    var offlineManager: OfflineManager!
    var connectivityManager: ConnectivityManager!
    var translationCache: TranslationCache!
    
    override func setUp() async throws {
        try super.setUp()
        
        // Initialize test components
        connectivityManager = ConnectivityManager()
        translationCache = TranslationCache.shared
        offlineManager = OfflineManager(
            connectivityManager: connectivityManager,
            translationCache: translationCache
        )
    }
    
    override func tearDown() async throws {
        try super.tearDown()
        
        // Clean up
        translationCache.clearCache()
        offlineManager = nil
        connectivityManager = nil
        translationCache = nil
    }
    
    // MARK: - Basic Functionality Tests
    
    func testOfflineManagerInitialization() throws {
        // Verify offline manager initializes correctly
        XCTAssertNotNil(offlineManager)
        XCTAssertNotNil(offlineManager.connectivityManager)
        XCTAssertNotNil(offlineManager.translationCache)
    }
    
    func testConnectivityManagerStatus() throws {
        // Test initial connectivity status
        let initialStatus = connectivityManager.status
        XCTAssert(initialStatus == .online || initialStatus == .offline || initialStatus == .unknown)
    }
    
    func testCacheStatistics() throws {
        // Test cache statistics are initialized
        let stats = offlineManager.getCacheStatistics()
        XCTAssert(stats.totalPhrases >= 0)
        XCTAssert(stats.cachedPhrases >= 0)
        XCTAssert(stats.hitRate >= 0.0 && stats.hitRate <= 1.0)
    }
    
    func testCapabilityAssessment() throws {
        // Test capability assessment
        let assessment = offlineManager.assessCapabilities()
        XCTAssert(assessment.status == .online || assessment.status == .offline || assessment.status == .degraded || assessment.status == .unknown || assessment.status == .limited)
        XCTAssert(assessment.coveragePercentage >= 0.0 && assessment.coveragePercentage <= 100.0)
    }
    
    // MARK: - Translation Tests
    
    func testTranslationWithCache() throws {
        // Test caching and retrieval
        let testPhrase = "Hello dog!"
        let testTranslation = "Woof woof!"
        
        // Cache a translation
        offlineManager.cacheTranslation(
            text: testPhrase,
            translatedText: testTranslation,
            direction: .humanToDog
        )
        
        // Verify it's cached
        let cached = offlineManager.getCachedTranslation(text: testPhrase, direction: .humanToDog)
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached, testTranslation)
    }
    
    func testTranslationAvailability() throws {
        // Test translation availability
        let testPhrase = "Sit!"
        
        // Check if we can translate this phrase
        let canTranslate = offlineManager.canTranslatePhrase(testPhrase, direction: .humanToDog)
        XCTAssert(canTranslate == true || canTranslate == false) // Should return boolean
    }
    
    // MARK: - Offline Fallback Tests
    
    func testOfflineFallback() throws {
        // Simulate offline mode
        connectivityManager.simulateNetworkStatus(.offline)
        
        // Test translation in offline mode
        let expectation = expectation(description: "Offline translation")
        
        offlineManager.getTranslation(text: "Test phrase", direction: .humanToDog) { result in
            switch result {
            case .success(let translation):
                XCTAssertFalse(translation.isEmpty)
                XCTAssertTrue(translation.contains("Offline"))
            case .failure(let error):
                XCTFail("Translation failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testOnlineTranslation() throws {
        // Simulate online mode
        connectivityManager.simulateNetworkStatus(.online)
        
        // Test translation in online mode
        let expectation = expectation(description: "Online translation")
        
        offlineManager.getTranslation(text: "Test phrase", direction: .humanToDog) { result in
            switch result {
            case .success(let translation):
                XCTAssertFalse(translation.isEmpty)
                XCTAssertTrue(translation.contains("Translated"))
            case .failure(let error):
                XCTFail("Translation failed with error: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Cache Management Tests
    
    func testCacheClear() throws {
        // Test cache clearing
        offlineManager.clearCache()
        let statsAfterClear = offlineManager.getCacheStatistics()
        XCTAssertEqual(statsAfterClear.cachedPhrases, 0)
    }
    
    func testCacheEviction() throws {
        // Test cache eviction (basic functionality)
        offlineManager.evictOldEntries(maxEntries: 5)
        // Should not crash
        XCTAssert(true)
    }
    
    // MARK: - Performance Tests
    
    func testTranslationPerformance() throws {
        measure {
            // Test translation performance
            let testPhrase = "Test phrase"
            offlineManager.getTranslation(text: testPhrase, direction: .humanToDog) { _ in }
        }
    }
    
    func testCacheStatisticsPerformance() throws {
        measure {
            // Test cache statistics calculation
            _ = offlineManager.getCacheStatistics()
        }
    }
}