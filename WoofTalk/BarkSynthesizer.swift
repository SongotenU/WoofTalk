import AVFoundation
import Combine

/// Synthesizes dog-like sounds and reads translations aloud
class BarkSynthesizer: ObservableObject {
    @Published var isSpeaking = false

    private let speechSynth = AVSpeechSynthesizer()
    private let engine = AVAudioEngine()

    // MARK: - Bark Sound Synthesis

    /// Play a synthesized bark sound based on the bark text response
    func playBark(_ text: String, completion: (() -> Void)? = nil) {
        let lowercased = text.lowercased()

        if lowercased.contains("woof") || lowercased.contains("bark") {
            playBarkSound(count: countOccurrences(text, "woof") + countOccurrences(text, "bark")) {
                completion?()
            }
        } else if lowercased.contains("whin") {
            playWhine()
            completion?()
        } else if lowercased.contains("growl") || lowercased.contains("ears down") {
            playGrowl()
            completion?()
        } else {
            playBarkSound(count: 1) { completion?() }
        }
    }

    /// Speak the human translation aloud using Text-to-Speech
    func speakTranslation(_ text: String, completion: (() -> Void)? = nil) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 0.9
        utterance.postUtteranceDelay = 0.3

        speechSynth.stopSpeaking(at: .immediate)

        isSpeaking = true
        speechSynth.speak(utterance)

        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            if !self.speechSynth.isSpeaking {
                timer.invalidate()
                self.isSpeaking = false
                completion?()
            }
        }
    }

    // MARK: - Raw Sound Generation

    private func playBarkSound(count: Int, completion: (() -> Void)? = nil) {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let samplesPerBark = Int(format.sampleRate * 0.12)
        let gapBetweenBarks = Int(format.sampleRate * 0.15)

        // Generate a buffer with N barks
        let totalSamples = count * samplesPerBark + max(0, count - 1) * gapBetweenBarks + Int(format.sampleRate * 0.2)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples))!
        let floatData = buffer.floatChannelData![0]
        for i in 0..<totalSamples {
            var barkStart = 0
            var found = false
            for b in 0..<count {
                let start = b * (samplesPerBark + gapBetweenBarks)
                let local = i - start
                if local >= 0 && local < samplesPerBark {
                    barkStart = local
                    found = true
                    break
                }
            }
            if found {
                let t = Double(barkStart) / format.sampleRate
                let freq = 350.0 - t * 200.0
                let envelope = exp(-Double(barkStart) / Double(samplesPerBark)) * 0.5
                floatData[i] = Float(sin(2.0 * Double.pi * freq * t) * envelope)
            } else {
                floatData[i] = 0.0
            }
        }
        buffer.frameLength = AVAudioFrameCount(totalSamples)

        player.scheduleBuffer(buffer)
        try? engine.start()
        player.play()

        let duration = Double(totalSamples) / format.sampleRate
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            player.stop()
            self.engine.stop()
            completion?()
        }
    }

    private func playWhine() {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let sampleRate = format.sampleRate
        let totalSamples = Int(sampleRate * 0.8)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples))!
        let floatData = buffer.floatChannelData![0]

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let envelope = exp(-t / 0.5) * 0.3
            let freq = 400.0 - t * 50.0
            floatData[i] = Float(sin(2.0 * Double.pi * freq * t) * envelope)
        }
        buffer.frameLength = AVAudioFrameCount(totalSamples)

        player.scheduleBuffer(buffer)
        try? engine.start()
        player.play()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            player.stop()
            self.engine.stop()
        }
    }

    private func playGrowl() {
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        let sampleRate = format.sampleRate
        let totalSamples = Int(sampleRate * 1.0)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalSamples))!
        let floatData = buffer.floatChannelData![0]

        for i in 0..<totalSamples {
            let t = Double(i) / sampleRate
            let envelope = 0.25 * (t < 0.2 ? t / 0.2 : (t > 0.7 ? (1.0 - t) / 0.3 : 1.0))
            let freq = 120.0
            floatData[i] = Float(sin(2.0 * Double.pi * freq * t) * envelope * 0.7)
        }
        buffer.frameLength = AVAudioFrameCount(totalSamples)

        player.scheduleBuffer(buffer)
        try? engine.start()
        player.play()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            player.stop()
            self.engine.stop()
        }
    }

    private func countOccurrences(_ text: String, _ substring: String) -> Int {
        var count = 0
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: substring, range: searchRange) {
            count += 1
            searchRange = range.upperBound..<text.endIndex
        }
        return count
    }
}
