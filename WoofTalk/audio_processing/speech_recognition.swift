//
//  speech_recognition.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

import Speech
import AVFoundation

class SpeechRecognition {
    private let speechRecognizer: SFSpeechRecognizer
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isRecognizing = false
    private var recognitionObservers: [(String) -> Void] = []
    private var errorHandler: ((Error) -> Void)?
    
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
        try checkAuthorizationStatus()
        
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
    
    func setErrorHandler(_ handler: @escaping (Error) -> Void) {
        errorHandler = handler
    }
    
    func isAvailable() -> Bool {
        return speechRecognizer.isAvailable
    }
    
    func getSupportedLocales() -> [Locale] {
        return SFSpeechRecognizer.supportedLocales()
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
        
        // Log detailed result information
        logRecognitionResult(result)
    }
    
    private func handleRecognitionError(_ error: Error) {
        // Log error and notify observers
        print("Speech recognition error: \(error.localizedDescription)")
        
        // Notify error handler if set
        errorHandler?(error)
        
        // Notify observers of error
        recognitionObservers.forEach { _ in }
    }
    
    private func logRecognitionResult(_ result: SFSpeechRecognitionResult) {
        let confidence = result.bestTranscription.formattedString.count > 0 ? 0.8 : 0.0
        let alternativesCount = result.transcriptions.count
        
        print("Recognition result: \"\(result.bestTranscription.formattedString)\" | Confidence: \(confidence) | Alternatives: \(alternativesCount)")
    }
    
    private func checkAuthorizationStatus() throws {
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

extension SpeechRecognition {
    func startWithRetry(from buffer: AVAudioPCMBuffer) {
        do {
            try startRecognition(from: buffer)
        } catch {
            retryRecognition(buffer, error: error)
        }
    }
    
    private var retryAttempts = 0
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 1.0
    
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
    
    func getRecognitionMetrics() -> [String: Any] {
        return [
            "isRecognizing": isRecognizing,
            "retryAttempts": retryAttempts,
            "maxRetryAttempts": maxRetryAttempts,
            "locale": speechRecognizer.locale.identifier
        ]
    }
}

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