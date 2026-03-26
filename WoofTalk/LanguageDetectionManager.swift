import Foundation
import AVFoundation

// MARK: - LanguageDetectionManager

final class LanguageDetectionManager {
    static let shared = LanguageDetectionManager()
    
    private var isEnabled = false
    private var audioAnalyzer: AudioAnalyzer?
    private let detectionQueue = DispatchQueue(label: "com.wooftalk.languagedetection")
    private var detectionCallbacks: [(AnimalLanguage, Double) -> Void] = []
    
    var delegate: LanguageDetectionDelegate?
    
    private init() {
        setupAudioAnalyzer()
    }
    
    private func setupAudioAnalyzer() {
        audioAnalyzer = AudioAnalyzer()
    }
    
    func startDetection() {
        isEnabled = true
    }
    
    func stopDetection() {
        isEnabled = false
    }
    
    var isDetecting: Bool {
        return isEnabled
    }
    
    func detectLanguage(from audioBuffer: AVAudioPCMBuffer) -> LanguageDetectionResult {
        let startTime = Date()
        
        let frequencies = analyzeFrequencies(from: audioBuffer)
        let result = performLanguageDetection(frequencies: frequencies)
        
        let detectionTime = Date().timeIntervalSince(startTime)
        
        let detectionResult = LanguageDetectionResult(
            detectedLanguage: result.language,
            confidence: result.confidence,
            detectionTime: detectionTime,
            frequencies: frequencies
        )
        
        delegate?.languageDetectionManager(self, didDetect: detectionResult)
        
        return detectionResult
    }
    
    func detectLanguage(fromText text: String) -> LanguageDetectionResult {
        let normalizedText = text.lowercased()
        
        var scores: [AnimalLanguage: Double] = [:]
        
        for language in AnimalLanguage.allCases {
            var score: Double = 0
            
            for pattern in language.vocalizationPatterns {
                if normalizedText.contains(pattern) {
                    score += 0.2
                }
            }
            
            score = min(score, 1.0)
            scores[language] = score
        }
        
        let bestMatch = scores.max(by: { $0.value < $1.value }) ?? (.dog, 0)
        
        return LanguageDetectionResult(
            detectedLanguage: bestMatch.key,
            confidence: bestMatch.value,
            detectionTime: 0,
            frequencies: [:]
        )
    }
    
    func addDetectionCallback(_ callback: @escaping (AnimalLanguage, Double) -> Void) {
        detectionCallbacks.append(callback)
    }
    
    private func analyzeFrequencies(from buffer: AVAudioPCMBuffer) -> [Double: Double] {
        guard let channelData = buffer.floatChannelData else {
            return [:]
        }
        
        let frameLength = Int(buffer.frameLength)
        let channelDataValue = channelData.pointee
        let sampleRate = buffer.format.sampleRate
        
        var frequencies: [Double: Double] = [:]
        
        let binSize = sampleRate / Double(frameLength)
        
        for bin in 0..<min(frameLength / 2, 100) {
            let frequency = Double(bin) * binSize
            
            for language in AnimalLanguage.allCases {
                if language.frequencyRange.contains(frequency) {
                    let magnitude = abs(Double(channelDataValue[bin]))
                    frequencies[frequency, default: 0] += magnitude
                }
            }
        }
        
        return frequencies
    }
    
    private func performLanguageDetection(frequencies: [Double: Double]) -> (language: AnimalLanguage, confidence: Double) {
        var languageScores: [AnimalLanguage: Double] = [:]
        
        for language in AnimalLanguage.allCases {
            var score: Double = 0
            let range = language.frequencyRange
            
            for (frequency, magnitude) in frequencies {
                if range.contains(frequency) {
                    score += magnitude
                }
            }
            
            languageScores[language] = score
        }
        
        let maxScore = languageScores.values.max() ?? 0
        let totalScore = languageScores.values.reduce(0, +)
        
        var normalizedScores: [AnimalLanguage: Double] = [:]
        
        if totalScore > 0 {
            for (language, score) in languageScores {
                normalizedScores[language] = score / totalScore
            }
        } else {
            for language in AnimalLanguage.allCases {
                normalizedScores[language] = 1.0 / Double(AnimalLanguage.allCases.count)
            }
        }
        
        let sorted = normalizedScores.sorted { $0.value > $1.value }
        
        if let top = sorted.first, top.value >= language.confidenceThreshold {
            return (top.key, top.value)
        }
        
        return (.dog, 0.3)
    }
}

// MARK: - LanguageDetectionDelegate

protocol LanguageDetectionDelegate: AnyObject {
    func languageDetectionManager(_ manager: LanguageDetectionManager, didDetect result: LanguageDetectionResult)
}

// MARK: - LanguageDetectionResult

struct LanguageDetectionResult {
    let detectedLanguage: AnimalLanguage
    let confidence: Double
    let detectionTime: TimeInterval
    let frequencies: [Double: Double]
    
    var isConfident: Bool {
        return confidence >= detectedLanguage.confidenceThreshold
    }
    
    var description: String {
        return "\(detectedLanguage.displayName) (\(String(format: "%.1f", confidence * 100))%)"
    }
}

// MARK: - AudioAnalyzer

final class AudioAnalyzer {
    private let fftSize = 2048
    private let sampleRate: Double = 44100
    
    func analyze(buffer: AVAudioPCMBuffer) -> [Double: Double] {
        guard let channelData = buffer.floatChannelData else {
            return [:]
        }
        
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return [:] }
        
        var magnitudes: [Double: Double] = [:]
        
        let channelDataValue = channelData.pointee
        
        let binWidth = sampleRate / Double(fftSize)
        
        for i in 0..<min(frameLength, fftSize) {
            let frequency = Double(i) * binWidth
            
            for language in AnimalLanguage.allCases {
                if language.frequencyRange.contains(frequency) {
                    let sample = Double(channelDataValue[i])
                    magnitudes[frequency, default: 0] += abs(sample)
                }
            }
        }
        
        return magnitudes
    }
}
