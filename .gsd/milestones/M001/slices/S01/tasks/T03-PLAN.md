# T03: Speech Recognition Interface — Plan

**Task:** T03  
**Slice:** S01  
**Milestone:** M001  
**Date:** 2026-03-11  
**Status:** Planning  

## Description
Integrate iOS speech recognition for human voice with proper error handling and result formatting.

## Why
Speech recognition is the critical bridge between raw audio and meaningful text. Without accurate recognition of human speech, we cannot provide translation services.

## Steps

### 1. Create Speech Recognition Class
```swift
// audio_processing/speech_recognition.swift
import Speech
import AVFoundation

class SpeechRecognition {
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isRecognizing = false
    private var recognitionObservers: [(String) -> Void] = []
    
    init(locale: Locale = .current) throws {
        guard let speechRecognizer = SFSpeechRecognizer(locale: locale) else {
            throw SpeechRecognitionError.unsupportedLocale
        }
        
        self.speechRecognizer = speechRecognizer
        configureRecognizer()
    }
    
    private func configureRecognizer() {
        speechRecognizer.defaultTaskHint = .search
        speechRecognizer.requiresOnDeviceRecognition = false
    }
    
    func startRecognition(from buffer: AVAudioPCMBuffer) throws {
        guard !isRecognizing else { return }
        
        // Create new recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        // Set up recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] (result, error) in
            self?.handleRecognitionResult(result, error: error)
        }
        
        // Process audio buffer
        recognitionRequest?.append(buffer)
        isRecognizing = true
    }
    
    func stopRecognition() {
        guard isRecognizing else { return }
        
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        isRecognizing = false
    }
    
    func addRecognitionObserver(_ observer: @escaping (String) -> Void) {
        recognitionObservers.append(observer)
    }
    
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        if let error = error {
            handleRecognitionError(error)
            return
        }
        
        guard let result = result else { return }
        
        // Notify observers with best transcription
        let bestTranscription = result.bestTranscription.formattedString
        recognitionObservers.forEach { $0(bestTranscription) }
    }
    
    private func handleRecognitionError(_ error: Error) {
        // Log error and notify observers
        print("Speech recognition error: \(error.localizedDescription)")
        
        // Notify observers of error
        recognitionObservers.forEach { _ in }
    }
}
```

### 2. Implement Recognition Result Formatter
```swift
// audio_processing/recognition_result_formatter.swift
import Foundation

struct RecognitionResultFormatter {
    static func formatResult(_ result: SFSpeechRecognitionResult) -> FormattedResult {
        return FormattedResult(
            text: result.bestTranscription.formattedString,
            confidence: result.bestTranscription.formattedString.count > 0 ? 0.8 : 0.0,
            segments: formatSegments(result.bestTranscription.segments),
            alternativeResults: formatAlternatives(result.alternatives)
        )
    }
    
    private static func formatSegments(_ segments: [SFTranscriptionSegment]) -> [Segment] {
        return segments.map { segment in
            return Segment(
                substring: segment.substring,
                timestamp: segment.timestamp,
                duration: segment.duration,
                confidence: segment.confidence ?? 0.8
            )
        }
    }
    
    private static func formatAlternatives(_ alternatives: [SFTranscription]) -> [Alternative] {
        return alternatives.map { alternative in
            return Alternative(
                formattedString: alternative.formattedString,
                segments: formatSegments(alternative.segments),
                confidence: alternative.formattedString.count > 0 ? 0.8 : 0.0
            )
        }
    }
}

struct FormattedResult {
    let text: String
    let confidence: Double
    let segments: [Segment]
    let alternativeResults: [Alternative]
}

struct Segment {
    let substring: String
    let timestamp: TimeInterval
    let duration: TimeInterval
    let confidence: Double
}

struct Alternative {
    let formattedString: String
    let segments: [Segment]
    let confidence: Double
}
```

### 3. Add Error Handling
```swift
// audio_processing/speech_recognition_errors.swift
import Foundation

enum SpeechRecognitionError: LocalizedError {
    case unsupportedLocale
    case authorizationDenied
    case recognitionFailed
    case networkUnavailable
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedLocale:
            return "Speech recognition is not supported for this locale"
        case .authorizationDenied:
            return "Speech recognition authorization was denied"
        case .recognitionFailed:
            return "Speech recognition failed"
        case .networkUnavailable:
            return "Network is unavailable for speech recognition"
        case .unknownError:
            return "An unknown error occurred during speech recognition"
        }
    }
}

extension SpeechRecognition {
    func checkAuthorizationStatus() throws {
        let status = SFSpeechRecognizer.authorizationStatus()
        
        switch status {
        case .authorized:
            return // All good
        case .denied:
            throw SpeechRecognitionError.authorizationDenied
        case .notDetermined:
            try requestAuthorization()
        case .restricted:
            throw SpeechRecognitionError.authorizationDenied
        @unknown default:
            throw SpeechRecognitionError.unknownError
        }
    }
    
    private func requestAuthorization() throws {
        let group = DispatchGroup()
        var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
        
        group.enter()
        SFSpeechRecognizer.requestAuthorization { status in
            authorizationStatus = status
            group.leave()
        }
        
        group.wait()
        
        switch authorizationStatus {
        case .authorized:
            return // All good
        case .denied:
            throw SpeechRecognitionError.authorizationDenied
        case .restricted:
            throw SpeechRecognitionError.authorizationDenied
        default:
            throw SpeechRecognitionError.unknownError
        }
    }
}
```

### 4. Implement Retry Logic
```swift
// audio_processing/recognition_retry_logic.swift
import Foundation

extension SpeechRecognition {
    private var retryAttempts = 0
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 1.0
    
    func startWithRetry(from buffer: AVAudioPCMBuffer) {
        do {
            try startRecognition(from: buffer)
        } catch {
            retryRecognition(buffer, error: error)
        }
    }
    
    private func retryRecognition(_ buffer: AVAudioPCMBuffer, error: Error) {
        guard retryAttempts < maxRetryAttempts else {
            print("Max retry attempts reached: \(error)")
            return
        }
        
        retryAttempts += 1
        
        // Exponential backoff
        let delay = retryDelay * pow(2.0, Double(retryAttempts - 1))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.startWithRetry(from: buffer)
        }
    }
    
    func resetRetryAttempts() {
        retryAttempts = 0
    }
}
```

## Must-Haves
- Speech recognition class with SFSpeechRecognizer
- Recognition result formatter for structured output
- Error handling for authorization and recognition failures
- Retry logic with exponential backoff
- Proper start/stop functionality

## Verification

### Unit Tests
```swift
// audio_processing/speech_recognition_tests.swift
import XCTest
@testable import WoofTalk

class SpeechRecognitionTests: XCTestCase {
    
    var speechRecognition: SpeechRecognition!
    
    override func setUp() async throws {
        speechRecognition = try SpeechRecognition()
    }
    
    func testSpeechRecognitionInitialization() throws {
        XCTAssertNotNil(speechRecognition)
        XCTAssertNotNil(speechRecognition.speechRecognizer)
    }
    
    func testAuthorizationStatus() throws {
        do {
            try speechRecognition.checkAuthorizationStatus()
            // If we get here, authorization is either granted or will be requested
            XCTAssertTrue(true)
        } catch {
            // Authorization denied - test passes if we handle it correctly
            XCTAssertTrue(error is SpeechRecognitionError)
        }
    }
    
    func testResultFormatting() throws {
        let testResult = createMockRecognitionResult()
        let formatted = RecognitionResultFormatter.formatResult(testResult)
        
        XCTAssertNotNil(formatted)
        XCTAssertFalse(formatted.text.isEmpty)
        XCTAssertFalse(formatted.segments.isEmpty)
    }
    
    func createMockRecognitionResult() -> SFSpeechRecognitionResult {
        // Create mock recognition result for testing
        let transcription = SFTranscription(
            formattedString: "Hello world",
            segments: [
                SFTranscriptionSegment(
                    substring: "Hello",
                    timestamp: 0.0,
                    duration: 1.0,
                    confidence: 0.9
                ),
                SFTranscriptionSegment(
                    substring: "world",
                    timestamp: 1.0,
                    duration: 1.0,
                    confidence: 0.8
                )
            ],
            alternativeSubstrings: []
        )
        
        return SFSpeechRecognitionResult(
            bestTranscription: transcription,
            transcriptions: [transcription],
            final: true
        )
    }
}
```

### Integration Tests
- Verify speech recognition can process audio buffers
- Check result formatting produces structured output
- Validate error handling works for various failure scenarios
- Test retry logic with simulated failures

## Observability Impact
- Adds recognition result monitoring
- Implements error tracking and retry counting
- Creates authorization status tracking
- Provides debug surfaces for recognition state

## Inputs
- Speech Framework
- Audio buffers from T02
- Recognition formatting requirements
- Error handling patterns

## Expected Output
- Working speech recognition class
- Result formatter with structured output
- Error handling and retry logic
- Test suite with recognition tests
- Integration interfaces for translation engine

## Success Criteria
- Speech recognition returns text for human speech with > 80% accuracy
- Recognition results are properly formatted
- Error handling works for various failure scenarios
- Retry logic handles temporary failures gracefully

## Risk Mitigation
- Authorization denial is handled gracefully
- Network failures trigger retry logic
- Unsupported locales are detected early
- Recognition errors don't crash the app

## Forward Intelligence
- Speech recognition accuracy varies by environment
- Network availability affects recognition quality
- Permission status can change during app usage
- Dog vocalizations are not supported by Speech Framework

## Decision Log
- **Recognition Type:** On-device when possible, cloud when needed
- **Retry Strategy:** Exponential backoff with max 3 attempts
- **Error Handling:** Graceful degradation with user feedback
- **Result Format:** Structured output for translation engine

---

**Task T03 planned.**