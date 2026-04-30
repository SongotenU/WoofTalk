import Foundation
import AVFoundation

final class AudioTranslationBridge {
    private let translationEngine: TranslationEngine
    private let audioEngine = AVAudioEngine()
    private var isProcessing = false

    weak var delegate: AudioTranslationBridgeDelegate?

    init(translationEngine: TranslationEngine) {
        self.translationEngine = translationEngine
        setupAudioEngine()
    }

    func startProcessing() throws {
        guard !isProcessing else { return }
        try audioEngine.start()
        isProcessing = true
        delegate?.audioTranslationBridgeDidStart(self)
    }

    func stopProcessing() {
        guard isProcessing else { return }
        audioEngine.stop()
        isProcessing = false
        delegate?.audioTranslationBridgeDidStop(self)
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        translateAudioBuffer(buffer, at: time) { [weak self] result in
            guard let self else { return }
            self.delegate?.audioTranslationBridge(self, didProcessBuffer: buffer, withResult: result, processingTime: 0)
        }
    }

    func translateText(_ text: String, completion: @escaping (Result<String, Error>) -> Void) {
        translationEngine.translateHumanToDog(text, completion: completion)
    }

    func synthesizeDogVocalization(from text: String, completion: @escaping (Result<Data, Error>) -> Void) {
        synthesizeBasicDogVocalization(from: text, completion: completion)
    }

    private func setupAudioEngine() {
        guard let inputNode = audioEngine.inputNode else { return }
        let inputFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, at: time)
        }
        audioEngine.connect(inputNode, to: audioEngine.mainMixerNode, format: inputFormat)
    }

    private func translateAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime, completion: @escaping (Result<String, Error>) -> Void) {
        speechRecognitionFromAudioBuffer(buffer) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let text):
                self.translationEngine.translateHumanToDog(text) { completion($0) }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func speechRecognitionFromAudioBuffer(_ buffer: AVAudioPCMBuffer, completion: @escaping (Result<String, Error>) -> Void) {
        guard let floatChannelData = buffer.floatChannelData else {
            completion(.failure(AudioTranslationError.speechRecognitionFailed))
            return
        }

        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        var dominantFrequency: Double = 0
        var totalEnergy: Double = 0

        for frame in 0..<frameCount {
            for channel in 0..<channelCount {
                let sample = floatChannelData[channel][frame]
                totalEnergy += Double(sample * sample)
                if frame > 0 {
                    let delta = Double(sample - floatChannelData[channel][frame - 1])
                    if abs(delta) > abs(dominantFrequency) { dominantFrequency = delta }
                }
            }
        }

        let averageEnergy = totalEnergy / Double(frameCount * channelCount)
        let textLength = Int(averageEnergy * 10) + 1

        let words = ["woof", "bark", "ruff", "yip", "arf", "grr", "howl", "growl", "sniff", "pant"]
        var result = ""
        for _ in 0..<textLength {
            if let word = words.randomElement() { result += word + " " }
        }

        if dominantFrequency > 0.5 {
            result = "excited " + result
        } else if dominantFrequency < -0.5 {
            result = "angry " + result
        } else {
            result = "normal " + result
        }

        completion(.success(result.trimmingCharacters(in: .whitespaces)))
    }

    private func synthesizeBasicDogVocalization(from text: String, completion: @escaping (Result<Data, Error>) -> Void) {
        let words = text.components(separatedBy: .whitespaces)
        var audioData = Data()

        for word in words {
            do {
                let toneData = try generateDogTone(frequency: 500 + Double.random(in: -200...200), duration: 0.3)
                audioData.append(toneData)
            } catch {
                completion(.failure(error))
                return
            }
        }

        completion(.success(audioData))
    }

    private func generateDogTone(frequency: Double, duration: TimeInterval) throws -> Data {
        guard let format = AudioFormats.pcmFormat else {
            throw AudioTranslationError.formatNotAvailable
        }

        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioTranslationError.bufferCreationFailed
        }

        let channelCount = Int(format.channelCount)
        let phaseIncrement = Float(2.0 * Double.pi * frequency / sampleRate)

        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            var phase: Float = 0
            var modulation: Float = 0

            for frame in 0..<Int(frameCount) {
                let amplitude = 0.3 + 0.2 * sin(Float(2 * Double.pi * 5 * Double(frame) / sampleRate))
                channelData[frame] = sin(phase) * amplitude
                phase += phaseIncrement
                modulation += 0.01 * sin(Float(2 * Double.pi * 2 * Double(frame) / sampleRate))
                phase += modulation
            }
        }

        buffer.frameLength = frameCount
        return bufferToData(buffer)
    }

    private func bufferToData(_ buffer: AVAudioPCMBuffer) -> Data {
        guard let format = buffer.format else { return Data() }
        let channelCount = Int(format.channelCount)
        let frameCount = Int(buffer.frameLength)
        let bytesPerFrame = format.streamDescription.pointee.mBytesPerFrame
        var data = Data(capacity: frameCount * channelCount * Int(bytesPerFrame))

        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<frameCount {
                let sample = channelData[frame]
                data.append(Data(bytes: &sample, count: MemoryLayout<Float>.size))
            }
        }

        return data
    }
}

protocol AudioTranslationBridgeDelegate: AnyObject {
    func audioTranslationBridgeDidStart(_ bridge: AudioTranslationBridge)
    func audioTranslationBridgeDidStop(_ bridge: AudioTranslationBridge)
    func audioTranslationBridge(_ bridge: AudioTranslationBridge, didProcessBuffer buffer: AVAudioPCMBuffer, withResult result: Result<String, Error>, processingTime: TimeInterval)
    func audioTranslationBridge(_ bridge: AudioTranslationBridge, didFailWithError error: Error)
}

enum AudioTranslationError: Error, LocalizedError {
    case speechRecognitionFailed
    case translationFailed
    case audioProcessingFailed
    case formatNotAvailable
    case bufferCreationFailed
    case synthesisFailed

    var errorDescription: String? {
        switch self {
        case .speechRecognitionFailed: return "Speech recognition failed"
        case .translationFailed: return "Translation failed"
        case .audioProcessingFailed: return "Audio processing failed"
        case .formatNotAvailable: return "Audio format not available"
        case .bufferCreationFailed: return "Audio buffer creation failed"
        case .synthesisFailed: return "Audio synthesis failed"
        }
    }
}