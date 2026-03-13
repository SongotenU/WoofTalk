import XCTest
@testable import WoofTalk

final class PerformanceTests: XCTestCase {
    
    func testTranslationLatency() throws {
        let engine = TranslationEngine.shared
        let testPhrases = [
            "Hello",
            "Sit down",
            "Good boy",
            "Come here please",
            "Stay quiet",
            "Go fetch",
            "Roll over",
            "Shake hands",
            "Speak",
            "Quiet"
        ]
        
        var totalLatency: TimeInterval = 0
        let iterations = 100
        
        for _ in 0..<iterations {
            for phrase in testPhrases {
                let startTime = Date()
                _ = engine.translateHumanToDog(phrase)
                let endTime = Date()
                totalLatency += endTime.timeIntervalSince(startTime)
            }
        }
        
        let avgLatency = (totalLatency / Double(iterations * testPhrases.count)) * 1000
        XCTAssertLessThan(avgLatency, 2000, "Average translation latency should be <2000ms, got \(avgLatency)ms")
    }
    
    func testBatteryUsage() throws {
        // Simulate continuous translation usage
        let engine = TranslationEngine.shared
        let testPhrase = "Continuous translation test"
        let iterations = 1000
        
        // Measure initial resource usage
        let initialMetrics = engine.getPerformanceMetrics()
        
        // Run translation iterations
        for _ in 0..<iterations {
            _ = engine.translateHumanToDog(testPhrase)
        }
        
        // Measure final resource usage
        let finalMetrics = engine.getPerformanceMetrics()
        
        let cpuTime = finalMetrics.cpuTime - initialMetrics.cpuTime
        let memoryUsage = finalMetrics.memoryUsage - initialMetrics.memoryUsage
        
        // Should be reasonable for 1000 translations
        XCTAssertLessThan(cpuTime, 10.0, "CPU time for 1000 translations should be <10 seconds")
        XCTAssertLessThan(memoryUsage, 50 * 1024 * 1024, "Memory usage should be <50MB")
    }
    
    func testMemoryUsage() throws {
        let engine = TranslationEngine.shared
        let initialMemory = engine.getMemoryUsage()
        
        // Create many translation instances
        var instances: [TranslationEngine] = []
        for _ in 0..<100 {
            instances.append(TranslationEngine())
        }
        
        let finalMemory = engine.getMemoryUsage()
        let memoryDelta = finalMemory - initialMemory
        
        XCTAssertLessThan(memoryDelta, 10 * 1024 * 1024, "Memory usage should be <10MB for 100 instances")
    }
    
    func testConcurrentPerformance() throws {
        let engine = TranslationEngine.shared
        let testPhrase = "Concurrent translation test"
        let iterations = 1000
        
        let queue = DispatchQueue(label: "translationQueue", attributes: .concurrent)
        let group = DispatchGroup()
        var results: [String] = []
        
        let startTime = Date()
        
        for _ in 0..<iterations {
            group.enter()
            queue.async {
                let result = engine.translateHumanToDog(testPhrase)
                results.append(result)
                group.leave()
            }
        }
        
        let result = group.wait(timeout: .now() + 10.0)
        let endTime = Date()
        
        XCTAssert(result == .success, "Concurrent translation should complete within 10 seconds")
        XCTAssertLessThan(endTime.timeIntervalSince(startTime), 5.0, "Concurrent translation should take <5 seconds")
        
        // Verify results
        XCTAssertFalse(results.isEmpty, "Should have results from concurrent translations")
    }
}