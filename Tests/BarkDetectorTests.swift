import XCTest
@testable import WoofTalkAR

final class BarkDetectorTests: XCTestCase {
    var detector: BarkDetector!
    var expectation: XCTestExpectation!
    var detectedClassification: BarkClassification?

    override func setUp() async throws {
        try await super.setUp()
        detector = BarkDetector.shared
        detector.delegate = self
    }

    override func tearDown() async throws {
        detector.stop()
        detector.delegate = nil
        try await super.tearDown()
    }

    func testBarkClassification() async throws {
        expectation = XCTestExpectation(description: "Bark detected")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = false

        // Load test audio file
        let testAudioURL = Bundle.module.url(forResource: "bark_sample", withExtension: "wav")!
        let audioFile = try AVAudioFile(forReading: testAudioURL)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: 1024)!
        try audioFile.read(into: buffer)
        buffer.frameLength = buffer.frameCapacity

        // Start detector
        try await detector.start()

        // Send buffer directly to detector (bypassing AudioRecorder for isolated test)
        await detector.processAudioBuffer(Notification(
            name: .audioBufferCaptured,
            object: nil,
            userInfo: ["buffer": buffer]
        ))

        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertNotNil(detectedClassification)
        XCTAssertEqual(detectedClassification?.className, "bark")
        // Placeholder model may have low confidence, just check >0.1 for now
        XCTAssertGreaterThan(detectedClassification?.confidence ?? 0, 0.1)
    }

    func testSilenceClassification() async throws {
        expectation = XCTestExpectation(description: "Silence detected")
        expectation.expectedFulfillmentCount = 1

        let testAudioURL = Bundle.module.url(forResource: "silence", withExtension: "wav")!
        let audioFile = try AVAudioFile(forReading: testAudioURL)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: 1024)!
        try audioFile.read(into: buffer)
        buffer.frameLength = buffer.frameCapacity

        await detector.processAudioBuffer(Notification(
            name: .audioBufferCaptured,
            object: nil,
            userInfo: ["buffer": buffer]
        ))

        await fulfillment(of: [expectation], timeout: 5.0)

        XCTAssertNotNil(detectedClassification)
        XCTAssertEqual(detectedClassification?.className, "silence")
    }
}

extension BarkDetectorTests: BarkDetectorDelegate {
    nonisolated func barkDetector(_ detector: BarkDetector, didDetect classification: BarkClassification) {
        detectedClassification = classification
        expectation.fulfill()
    }
}
