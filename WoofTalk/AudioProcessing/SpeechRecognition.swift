import AVFoundation
import Speech

final class SpeechRecognition: NSObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    weak var delegate: SpeechRecognitionDelegate?

    override init() {
        let locale = Locale(identifier: "en_US")
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
        speechRecognizer?.delegate = self
    }

    func startRecognition() throws {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw SpeechRecognitionError.authorizationDenied
        }
        guard speechRecognizer?.isAvailable ?? false else {
            throw SpeechRecognitionError.notAvailable
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        recognitionRequest = request
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            self?.handleRecognitionResult(result, error: error)
        }
        delegate?.speechRecognitionDidStart(self)
    }

    func stopRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        delegate?.speechRecognitionDidStop(self)
    }

    func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        recognitionRequest?.append(buffer)
        let duration = Double(buffer.frameLength) / (buffer.format?.sampleRate ?? 16000.0)
        delegate?.speechRecognition(self, didProcessBufferWithDuration: duration)
    }

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        delegate?.speechRecognition(self, availabilityDidChange: available)
    }

    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        if let result = result {
            let bestTranscription = result.bestTranscription.formattedString
            delegate?.speechRecognition(self, didRecognizeSpeech: bestTranscription)
            if result.isFinal {
                delegate?.speechRecognition(self, didCompleteFinalRecognition: bestTranscription)
            }
        }
        if let error = error {
            delegate?.speechRecognition(self, didFailWithError: error)
        }
    }

    var currentLocale: Locale? { speechRecognizer?.locale }
    var isAvailable: Bool { speechRecognizer?.isAvailable ?? false }

    static var supportedLocales: [Locale] {
        SFSpeechRecognizer.supportedLocales().map { $0 }
    }

    static func requestAuthorization(completion: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { completion(status) }
        }
    }

    static var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        SFSpeechRecognizer.authorizationStatus()
    }
}

protocol SpeechRecognitionDelegate: AnyObject {
    func speechRecognitionDidStart(_ recognition: SpeechRecognition)
    func speechRecognitionDidStop(_ recognition: SpeechRecognition)
    func speechRecognition(_ recognition: SpeechRecognition, didRecognizeSpeech text: String)
    func speechRecognition(_ recognition: SpeechRecognition, didCompleteFinalRecognition text: String)
    func speechRecognition(_ recognition: SpeechRecognition, didFailWithError error: Error)
    func speechRecognition(_ recognition: SpeechRecognition, didProcessBufferWithDuration duration: Double)
    func speechRecognition(_ recognition: SpeechRecognition, availabilityDidChange available: Bool)
}

enum SpeechRecognitionError: Error, LocalizedError {
    case authorizationDenied
    case notAvailable
    case recognitionFailed
    case bufferProcessingFailed

    var errorDescription: String? {
        switch self {
        case .authorizationDenied: return "Speech recognition authorization denied"
        case .notAvailable: return "Speech recognition not available"
        case .recognitionFailed: return "Speech recognition failed"
        case .bufferProcessingFailed: return "Speech buffer processing failed"
        }
    }
}
