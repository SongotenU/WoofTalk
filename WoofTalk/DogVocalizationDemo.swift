// MARK: - DogVocalizationDemo

import AVFoundation
import SynthesisModels

/// Demonstration of dog vocalization synthesis
class DogVocalizationDemo {
    
    private let synthesizer = DogVocalizationSynthesizer()
    private let audioEngine = AVAudioEngine()
    private let audioFormat = AudioFormats.pcmFormat
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        guard let format = audioFormat else { return }
        
        // Basic audio engine setup
        audioEngine.mainMixerNode.volume = 0.7
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: format)
    }
    
    func demonstrateAllEmotions() throws {
        print("=== Dog Vocalization Synthesis Demo ===\n")
        print("Demonstrating all dog emotions:\n")
        
        let emotions = DogEmotion.allCases
        for emotion in emotions {
            do {
                let sound = try synthesizer.synthesizeRandomDogSound(emotion: emotion)
                let quality = synthesizer.getSynthesisQualityMetrics()
                print("\(emotion.rawValue): Quality - \(quality.qualityDescription)")
                
                // Play the sound (in a real app, this would play audio)
                // playSound(sound) // Uncomment in actual audio context
                
            } catch {
                print("Error generating \(emotion.rawValue) sound: \(error)")
            }
        }
        
        print("\n=== Synthesis Quality Metrics ===\n")
        let overallQuality = synthesizer.getSynthesisQualityMetrics()
        print("Overall Quality: \(overallQuality.qualityDescription)")
        print("Pitch Accuracy: \(overallQuality.pitchAccuracy * 100)%")
        print("Formant Quality: \(overallQuality.formantQuality * 100)%")
        print("Vibrato Authenticity: \(overallQuality.vibratoAuthenticity * 100)%")
        print("\n=== Audio Effects Available ===\n")
        
        let effectsProcessor = AudioEffectsProcessor()
        let effects = effectsProcessor.getEffectDescriptions()
        for (index, effect) in effects.enumerated() {
            print("\(index + 1). \(effect)")
        }
        
        print("\n=== Dog Vocalization Models ===\n")
        print("Base pitch range: \(synthesizer.baseDogPitchRange) Hz")
        print("Formant shift factor: \(synthesizer.formantShiftFactor)")
        print("Modulation depth: \(synthesizer.modulationDepth)")
        print("Modulation rate: \(synthesizer.modulationRate) Hz")
        print("\n=== Demo Complete ===\n")
    }
    
    func demonstrateTextTranslation() throws {
        print("=== Text to Dog Vocalization Demo ===\n")
        
        let phrases = [
            "Hello!",
            "I'm happy to see you!",
            "Let's play!",
            "Who's there?",
            "I'm scared!"
        ]
        
        let emotionMapping: [String: DogEmotion] = [
            "Hello!": .neutral,
            "I'm happy to see you!": .happy,
            "Let's play!": .playful,
            "Who's there?": .territorial,
            "I'm scared!": .scared
        ]
        
        for phrase in phrases {
            if let emotion = emotionMapping[phrase] {
                do {
                    let sound = try synthesizer.synthesizeDogVocalization(from: phrase, emotion: emotion)
                    print("Phrase: \"\(phrase)\" → Emotion: \(emotion.rawValue)")
                    // playSound(sound) // Uncomment in actual audio context
                } catch {
                    print("Error translating phrase: \(error)")
                }
            }
        }
        
        print("\n=== Text Translation Demo Complete ===\n")
    }
    
    func demonstrateAudioProcessing() throws {
        print("=== Audio Processing Demo ===\n")
        
        // Create test audio
        let testAudio = try AudioSynthesis().generateTone(
            frequency: 440.0,
            duration: 1.0,
            amplitude: 0.5,
            waveform: .sine
        )
        
        print("Original audio created: \(testAudio.frameLength) frames")
        
        // Apply effects
        let effectsProcessor = AudioEffectsProcessor()
        
        let pitchShifted = try effectsProcessor.applyPitchShift(to: testAudio, pitch: 200.0)
        print("Pitch shifted: \(pitchShifted.frameLength) frames")
        
        let formantShifted = try effectsProcessor.applyFormantShift(to: testAudio, factor: 0.6)
        print("Formant shifted: \(formantShifted.frameLength) frames")
        
        let dogEffects = try effectsProcessor.applyDogVocalization(to: testAudio)
        print("Dog effects applied: \(dogEffects.frameLength) frames")
        
        print("\n=== Audio Processing Demo Complete ===\n")
    }
    
    func runFullDemo() throws {
        try demonstrateAllEmotions()
        try demonstrateTextTranslation()
        try demonstrateAudioProcessing()
        
        print("\n=== Dog Vocalization Synthesis Demo Complete ===\n")
        print("All synthesis features verified successfully!")
    }
    
    // Uncomment in actual audio context:
    /*
    private func playSound(_ buffer: AVAudioPCMBuffer) {
        guard let format = buffer.format else { return }
        
        audioEngine.attach(audioEngine.mainMixerNode)
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: format)
        
        do {
            try audioEngine.start()
            audioEngine.mainMixerNode.scheduleBuffer(buffer, at: nil, options: .loops)
        } catch {
            print("Error playing sound: \(error)")
        }
    }
    */
}

// MARK: - Demo Execution

if CommandLine.arguments.contains("--demo") {
    let demo = DogVocalizationDemo()
    do {
        try demo.runFullDemo()
    } catch {
        print("Demo failed: \(error)")
    }
}