// MARK: - DogVocalizationSynthesizer

import AVFoundation
import SynthesisModels

/// Handles realistic dog vocalization synthesis using audio effects and pitch shifting
final class DogVocalizationSynthesizer {

    private let audioEngine = AVAudioEngine()
    private let audioFormat = AudioFormats.pcmFormat
    private let effectsProcessor = AudioEffectsProcessor()
    private let synthesisQueue = DispatchQueue(label: "com.wooftalk.dogvocalization", qos: .userInitiated)

    init() {
        audioEngine.mainMixerNode.volume = 0.0
    }

    func synthesizeDogVocalization(from text: String, emotion: DogEmotion = .neutral) throws -> AVAudioPCMBuffer {
        try applyDogVocalizationEffects(to: AudioSynthesis().generateSpeech(from: text), emotion: emotion)
    }

    func synthesizeDogVocalization(from buffer: AVAudioPCMBuffer, emotion: DogEmotion = .neutral) throws -> AVAudioPCMBuffer {
        try applyDogVocalizationEffects(to: buffer, emotion: emotion)
    }

    func synthesizeRandomDogSound(emotion: DogEmotion = .neutral) throws -> AVAudioPCMBuffer {
        let tone = try AudioSynthesis().generateTone(
            frequency: Double.random(in: 150...600),
            duration: Double.random(in: 0.5...3.0),
            amplitude: 0.4,
            waveform: .square
        )
        return try applyDogVocalizationEffects(to: tone, emotion: emotion)
    }

    private func applyDogVocalizationEffects(to buffer: AVAudioPCMBuffer, emotion: DogEmotion) throws -> AVAudioPCMBuffer {
        let params = DogVocalizationPresets.parameter(for: emotion)
        var currentBuffer = try effectsProcessor.applyPitchShift(to: buffer, pitch: Double.random(in: params.pitchRange) - 440.0)
        currentBuffer = try effectsProcessor.applyFormantShift(to: currentBuffer, factor: params.formantShift)
        currentBuffer = try effectsProcessor.applyVibrato(to: currentBuffer, depth: params.vibratoDepth, rate: params.vibratoRate)
        currentBuffer = try applyAmplitudeModulation(to: currentBuffer, depth: params.modulationDepth, rate: params.modulationRate)
        currentBuffer = try effectsProcessor.applyCompression(to: currentBuffer, threshold: -25.0, ratio: 4.0)
        return try effectsProcessor.applyGain(to: currentBuffer, gain: Float.random(in: params.amplitudeRange))
    }

    private func applyAmplitudeModulation(to buffer: AVAudioPCMBuffer, depth: Float, rate: Double) throws -> AVAudioPCMBuffer {
        guard let format = buffer.format else { throw AudioEffectsError.formatNotAvailable }

        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.0
        delay.feedback = 0.0
        delay.wetDryMix = 100.0
        delay.lfoFrequency = Float(rate)
        delay.lfoDepth = depth

        let engine = AVAudioEngine()
        engine.attach(delay)
        engine.connect(buffer, to: delay, format: format)
        engine.connect(delay, to: engine.mainMixerNode, format: format)

        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameLength) else {
            throw AudioEffectsError.bufferCreationFailed
        }
        try engine.start()
        delay.render(to: output, timing: nil)
        engine.stop()
        return output
    }
}