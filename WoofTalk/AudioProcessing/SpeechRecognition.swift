// MARK: - SpeechRecognition

import AVFoundation
import Speech

/// Handles speech recognition for human voice using iOS Speech Framework
final class SpeechRecognition: NSObject, SFSpeechRecognizerDelegate {
    
    // MARK: Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isRecognizing = false
    
    // MARK: Delegates
    weak var delegate: SpeechRecognitionDelegate?
    
    // MARK: Initialization
    override init() {
        // Initialize speech recognizer with US English locale
        let locale = Locale(identifier: "en_US")
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
        
        speechRecognizer?.delegate = self
    }
    
    // MARK: Public Methods
    func startRecognition() throws {
        // Check speech recognition availability
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw SpeechRecognitionError.authorizationDenied
        }
        
        guard speechRecognizer?.isAvailable ?? false else {
            throw SpeechRecognitionError.notAvailable
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        // Configure request for real-time recognition
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] (result, error) in
            self?.handleRecognitionResult(result, error: error)
        }
        
        isRecognizing = true
        delegate?.speechRecognitionDidStart(self)
    }
    
    func stopRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecognizing = false
        delegate?.speechRecognitionDidStop(self)
    }
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        // Convert buffer to format suitable for speech recognition
        guard let recognitionRequest = recognitionRequest,
              let speechFormat = AudioFormats.speechRecognitionFormat else {
            return
        }
        
        // Append audio buffer to recognition request
        recognitionRequest.append(buffer)
        
        // Check buffer statistics
        let bufferDuration = Double(buffer.frameLength) / (buffer.format?.sampleRate ?? 16000.0)
        delegate?.speechRecognition(self, didProcessBufferWithDuration: bufferDuration)
    }
    
    // MARK: SFSpeechRecognizerDelegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        delegate?.speechRecognition(self, availabilityDidChange: available)
    }
    
    // MARK: Private Methods
    private func handleRecognitionResult(_ result: SFSpeechRecognitionResult?, error: Error?) {
        // Handle recognition result
        if let result = result {
            // Get best transcription
            let bestTranscription = result.bestTranscription.formattedString
            
            // Notify delegate
            delegate?.speechRecognition(self, didRecognizeSpeech: bestTranscription)
            
            // Check if final result
            if result.isFinal {
                delegate?.speechRecognition(self, didCompleteFinalRecognition: bestTranscription)
            }
        }
        
        // Handle error
        if let error = error {
            delegate?.speechRecognition(self, didFailWithError: error)
        }
    }
    
    // MARK: Speech Recognition Information
    var currentLocale: Locale? {
        return speechRecognizer?.locale
    }
    
    var isAvailable: Bool {
        return speechRecognizer?.isAvailable ?? false
    }
    
    var supportedLocales: [Locale] {
        return SFSpeechRecognizer.supportedLocales()
    }
    
    // MARK: Authorization
    static func requestAuthorization(completion: @escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }
    
    static var authorizationStatus: SFSpeechRecognizerAuthorizationStatus {
        return SFSpeechRecognizer.authorizationStatus()
    }
}

// MARK: - SpeechRecognitionDelegate

protocol SpeechRecognitionDelegate: AnyObject {
    func speechRecognitionDidStart(_ recognition: SpeechRecognition)
    func speechRecognitionDidStop(_ recognition: SpeechRecognition)
    func speechRecognition(_ recognition: SpeechRecognition, didRecognizeSpeech text: String)
    func speechRecognition(_ recognition: SpeechRecognition, didCompleteFinalRecognition text: String)
    func speechRecognition(_ recognition: SpeechRecognition, didFailWithError error: Error)
    func speechRecognition(_ recognition: SpeechRecognition, didProcessBufferWithDuration duration: Double)
    func speechRecognition(_ recognition: SpeechRecognition, availabilityDidChange available: Bool)
}

// MARK: - SpeechRecognition Errors

enum SpeechRecognitionError: Error, LocalizedError {
    case authorizationDenied
    case notAvailable
    case recognitionFailed
    case bufferProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Speech recognition authorization denied"
        case .notAvailable:
            return "Speech recognition not available"
        case .recognitionFailed:
            return "Speech recognition failed"
        case .bufferProcessingFailed:
            return "Speech buffer processing failed"
        }
    }
}

// MARK: - SpeechRecognition Extensions

extension SpeechRecognition {
    /// Get recognition statistics
    var recognitionStatistics: (processedBuffers: Int, recognizedText: String) {
        // This would need to be tracked with actual implementation
        return (0, "")
    }
    
    /// Check if recognition is running
    var isRunning: Bool {
        return isRecognizing
    }
    
    /// Get current recognition accuracy estimate
    var currentAccuracy: Double {
        // This would need actual accuracy tracking
        return 0.8
    }
}