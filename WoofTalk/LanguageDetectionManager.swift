import Foundation
import AVFoundation

final class LanguageDetectionManager {
    static let shared = LanguageDetectionManager()

    private var isEnabled = false

    func startDetection() { isEnabled = true }
    func stopDetection() { isEnabled = false }
    var isDetecting: Bool { isEnabled }

    func detectLanguage(from audioBuffer: AVAudioPCMBuffer) -> LanguageDetectionResult {
        let frequencies = analyzeFrequencies(from: audioBuffer)
        let result = performLanguageDetection(frequencies: frequencies)
        return LanguageDetectionResult(
            detectedLanguage: result.language, confidence: result.confidence,
            detectionTime: Date().timeIntervalSinceNow * -1, frequencies: frequencies
        )
    }

    func detectLanguage(fromText text: String) -> LanguageDetectionResult {
        let normalized = text.lowercased()
        let scores = AnimalLanguage.allCases.reduce(into: [AnimalLanguage: Double]()) { scores, language in
            scores[language] = Double(language.vocalizationPatterns.filter { normalized.contains($0) }.count) * 0.2
        }
        let best = scores.max(by: { $0.value < $1.value }) ?? (.dog, 0.0)
        return LanguageDetectionResult(detectedLanguage: best.key, confidence: best.value, detectionTime: 0, frequencies: [:])
    }

    private func analyzeFrequencies(from buffer: AVAudioPCMBuffer) -> [Double: Double] {
        guard let channelData = buffer.floatChannelData else { return [:] }
        let frameLength = Int(buffer.frameLength)
        let binWidth = buffer.format.sampleRate / Double(min(frameLength * 2, 2048))
        var frequencies: [Double: Double] = [:]
        let data = channelData.pointee
        for bin in 0..<min(frameLength / 2, 1024) {
            frequencies[Double(bin) * binWidth] = abs(Double(data[bin]))
        }
        return frequencies
    }

    private func performLanguageDetection(frequencies: [Double: Double]) -> (language: AnimalLanguage, confidence: Double) {
        var scores: [AnimalLanguage: Double] = [:]
        for (freq, mag) in frequencies {
            for language in AnimalLanguage.allCases where language.frequencyRange.contains(freq) {
                scores[language, default: 0] += mag
            }
        }
        let total = scores.values.reduce(0, +)
        let normalized = total > 0 ? scores.mapValues { $0 / total } : [AnimalLanguage: Double]()
        guard total > 0, let (lang, conf) = normalized.max(by: { $0.value < $1.value }), conf >= 0.3 else {
            return (.dog, 0.3)
        }
        return (lang, conf)
    }
}

struct LanguageDetectionResult {
    let detectedLanguage: AnimalLanguage
    let confidence: Double
    let detectionTime: TimeInterval
    let frequencies: [Double: Double]

    var isConfident: Bool { confidence >= detectedLanguage.confidenceThreshold }
    var description: String { "\(detectedLanguage.displayName) (\(String(format: "%.1f", confidence * 100))%)" }
}
