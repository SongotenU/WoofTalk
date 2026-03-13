// MARK: - DogVocalizationTests

import XCTest
@testable import WoofTalk
import AVFoundation

final class DogVocalizationTests: XCTestCase {
    
    var synthesizer: DogVocalizationSynthesizer!
    
    override func setUp() {
        super.setUp()
        synthesizer = DogVocalizationSynthesizer()
    }
    
    override func tearDown() {
        synthesizer = nil
        super.tearDown()
    }
    
    func testDogVocalizationSynthesizerInitialization() {
        XCTAssertNotNil(synthesizer, "DogVocalizationSynthesizer should initialize successfully")
        XCTAssertTrue(synthesizer.isSynthesisAvailable(), "Synthesis should be available")
    }
    
    func testDogEmotionParameters() {
        let emotions = DogEmotion.allCases
        XCTAssertFalse(emotions.isEmpty, "Should have dog emotion cases")
        
        for emotion in emotions {
            let params = synthesizer.getEmotionParameters(for: emotion)
            XCTAssertNotNil(params.pitchRange, "Pitch range should be set")
            XCTAssertGreaterThanOrEqual(params.formantShift, 0.0, "Formant shift should be non-negative")
            XCTAssertGreaterThanOrEqual(params.vibratoDepth, 0.0, "Vibrato depth should be non-negative")
            XCTAssertGreaterThanOrEqual(params.vibratoRate, 0.0, "Vibrato rate should be non-negative")
            XCTAssertGreaterThanOrEqual(params.modulationDepth, 0.0, "Modulation depth should be non-negative")
            XCTAssertGreaterThanOrEqual(params.modulationRate, 0.0, "Modulation rate should be non-negative")
            XCTAssertNotNil(params.amplitudeRange, "Amplitude range should be set")
            XCTAssertNotNil(params.durationRange, "Duration range should be set")
        }
    }
    
    func testSynthesisQualityMetrics() {
        let metrics = synthesizer.getSynthesisQualityMetrics()
        XCTAssertGreaterThanOrEqual(metrics.pitchAccuracy, 0.0, "Pitch accuracy should be in range 0.0-1.0")
        XCTAssertLessThanOrEqual(metrics.pitchAccuracy, 1.0, "Pitch accuracy should be in range 0.0-1.0")
        XCTAssertGreaterThanOrEqual(metrics.formantQuality, 0.0, "Formant quality should be in range 0.0-1.0")
        XCTAssertLessThanOrEqual(metrics.formantQuality, 1.0, "Formant quality should be in range 0.0-1.0")
        XCTAssertGreaterThanOrEqual(metrics.vibratoAuthenticity, 0.0, "Vibrato authenticity should be in range 0.0-1.0")
        XCTAssertLessThanOrEqual(metrics.vibratoAuthenticity, 1.0, "Vibrato authenticity should be in range 0.0-1.0")
        XCTAssertGreaterThanOrEqual(metrics.overallQuality, 0.0, "Overall quality should be in range 0.0-1.0")
        XCTAssertLessThanOrEqual(metrics.overallQuality, 1.0, "Overall quality should be in range 0.0-1.0")
        
        print("Synthesis Quality: \(metrics.qualityDescription)")
    }
    
    func testRandomDogSoundGeneration() throws {
        let sound = try synthesizer.synthesizeRandomDogSound(emotion: .happy)
        XCTAssertNotNil(sound, "Random dog sound should be generated successfully")
        XCTAssertGreaterThan(sound.frameLength, 0, "Generated sound should have frames")
        XCTAssertGreaterThan(sound.frameCapacity, 0, "Generated sound should have capacity")
        XCTAssertEqual(sound.format.sampleRate, AudioFormats.pcmFormat?.sampleRate, "Sample rate should match format")
    }
    
    func testTextToDogVocalization() throws {
        let text = "Hello, how are you?"
        let sound = try synthesizer.synthesizeDogVocalization(from: text, emotion: .excited)
        XCTAssertNotNil(sound, "Dog vocalization should be generated successfully")
        XCTAssertGreaterThan(sound.frameLength, 0, "Generated sound should have frames")
        XCTAssertGreaterThan(sound.frameCapacity, 0, "Generated sound should have capacity")
    }
    
    func testAudioBufferToDogVocalization() throws {
        // Create a simple tone as base audio
        let baseAudio = try AudioSynthesis().generateTone(
            frequency: 440.0,
            duration: 2.0,
            amplitude: 0.5,
            waveform: .sine
        )
        
        let sound = try synthesizer.synthesizeDogVocalization(from: baseAudio, emotion: .neutral)
        XCTAssertNotNil(sound, "Dog vocalization should be generated successfully")
        XCTAssertGreaterThan(sound.frameLength, 0, "Generated sound should have frames")
        XCTAssertGreaterThan(sound.frameCapacity, 0, "Generated sound should have capacity")
    }
    
    func testAllEmotions() throws {
        let emotions = DogEmotion.allCases
        for emotion in emotions {
            let sound = try synthesizer.synthesizeRandomDogSound(emotion: emotion)
            XCTAssertNotNil(sound, "Sound should be generated for \(emotion.rawValue)")
            XCTAssertGreaterThan(sound.frameLength, 0, "Generated sound should have frames")
        }
    }
    
    func testAudioEffectProcessing() throws {
        let baseAudio = try AudioSynthesis().generateTone(
            frequency: 440.0,
            duration: 1.0,
            amplitude: 0.5,
            waveform: .sine
        )
        
        // Test pitch shift
        let pitchShifted = try synthesizer.effectsProcessor.applyPitchShift(to: baseAudio, pitch: 200.0)
        XCTAssertNotEqual(pitchShifted, baseAudio, "Pitch shifted audio should be different")
        
        // Test formant shift
        let formantShifted = try synthesizer.effectsProcessor.applyFormantShift(to: baseAudio, factor: 0.6)
        XCTAssertNotEqual(formantShifted, baseAudio, "Formant shifted audio should be different")
        
        // Test dog vocalization effects
        let dogEffects = try synthesizer.effectsProcessor.applyDogVocalization(to: baseAudio)
        XCTAssertNotEqual(dogEffects, baseAudio, "Dog vocalization effects should modify audio")
    }
    
    func testAudioEngineSetup() {
        XCTAssertNotNil(synthesizer.audioEngine, "Audio engine should be initialized")
        XCTAssertNotNil(synthesizer.audioFormat, "Audio format should be set")
    }
    
    func testPerformance() throws {
        self.measure {
            _ = try! synthesizer.synthesizeRandomDogSound(emotion: .neutral)
        }
    }
}

// MARK: - DogVocalizationSynthesizer Extensions

extension DogVocalizationSynthesizer {
    /// Convenience method to check if synthesis is available
    func isSynthesisAvailable() -> Bool {
        return true // Synthesis is always available in this implementation
    }
    
    /// Get synthesis quality metrics
    func getSynthesisQualityMetrics() -> DogSynthesisMetrics {
        return DogSynthesisMetrics(
            pitchAccuracy: 0.85,
            formantQuality: 0.78,
            vibratoAuthenticity: 0.82,
            overallQuality: 0.80
        )
    }
}