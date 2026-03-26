// MARK: - RealTranslationController

import Foundation
import AVFoundation

final class RealTranslationController {
    
    // MARK: - Properties
    private let translationEngine: TranslationEngine
    private let aiTranslationService: AITranslationService
    private let audioCapture: AudioCapture
    private let speechRecognition: SpeechRecognition
    private let audioPlayback: AudioPlayback
    private let translationBridge: AudioTranslationBridge
    
    private var isTranslating = false
    private var translationStartTime: Date?
    private var totalTranslationTime: TimeInterval = 0
    private var translationCount = 0
    private var latencyThreshold: TimeInterval = 1.0
    
    // Streaming
    private var enableStreaming = false
    private var chunkSize: Int = 50
    private var streamingBuffer: String = ""
    private var lastPartialTranslation: String = ""
    private var streamingTask: Task<Void, Never>?
    
    // Continuous mode
    private var isContinuousMode = false
    private var continuousTimer: Timer?
    
    // Translation state
    enum TranslationState {
        case idle
        case capturing
        case recognizing
        case translating
        case playing
        case error
    }
    
    private var currentState: TranslationState = .idle
    private let stateLock = NSLock()
    
    // Performance metrics
    struct TranslationMetrics {
        var lastTranslationLatency: TimeInterval = 0
        var averageLatency: TimeInterval = 0
        var bufferProcessingTime: TimeInterval = 0
        var translationSuccessRate: Double = 0
        var totalTranslations: Int = 0
        var failedTranslations: Int = 0
        var streamingChunks: Int = 0
        var lastChunkLatency: TimeInterval = 0
    }
    
    private var metrics = TranslationMetrics()
    
    // MARK: - Delegates
    weak var delegate: RealTranslationControllerDelegate?
    
    // MARK: - Initialization
    init(translationEngine: TranslationEngine,
         audioCapture: AudioCapture,
         speechRecognition: SpeechRecognition,
         audioPlayback: AudioPlayback,
         translationBridge: AudioTranslationBridge) {
        
        self.translationEngine = translationEngine
        self.audioCapture = audioCapture
        self.speechRecognition = speechRecognition
        self.audioPlayback = audioPlayback
        self.translationBridge = translationBridge
        
        setupDelegates()
    }
    
    // MARK: - Public Methods
    func startTranslation() throws {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard currentState == .idle else {
            throw RealTranslationError.alreadyTranslating
        }
        
        // Reset metrics
        resetMetrics()
        
        // Start audio capture
        try audioCapture.startCapture()
        
        // Start speech recognition
        try speechRecognition.startRecognition()
        
        // Set initial state
        currentState = .capturing
        translationStartTime = Date()
        
        delegate?.realTranslationControllerDidStart(self)
    }
    
    func stopTranslation() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard currentState != .idle else { return }
        
        // Stop all components
        audioCapture.stopCapture()
        speechRecognition.stopRecognition()
        
        // Update metrics
        let endTime = Date()
        if let startTime = translationStartTime {
            totalTranslationTime = endTime.timeIntervalSince(startTime)
        }
        
        // Reset state
        currentState = .idle
        translationStartTime = nil
        
        delegate?.realTranslationControllerDidStop(self, totalTime: totalTranslationTime)
    }
    
    func pauseTranslation() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard currentState != .idle else { return }
        
        // Pause audio capture
        audioCapture.stopCapture()
        
        // Pause speech recognition
        speechRecognition.stopRecognition()
        
        delegate?.realTranslationControllerDidPause(self)
    }
    
    func resumeTranslation() throws {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard currentState == .idle else {
            throw RealTranslationError.notPaused
        }
        
        // Resume audio capture
        try audioCapture.startCapture()
        
        // Resume speech recognition
        try speechRecognition.startRecognition()
        
        delegate?.realTranslationControllerDidResume(self)
    }
    
    // MARK: - Metrics
    var currentLatency: TimeInterval {
        return metrics.lastTranslationLatency
    }
    
    var averageLatency: TimeInterval {
        return metrics.averageLatency
    }
    
    var isWithinLatencyThreshold: Bool {
        return metrics.lastTranslationLatency < latencyThreshold
    }
    
    var translationSuccessRate: Double {
        return metrics.translationSuccessRate
    }
    
    var performanceMetrics: TranslationMetrics {
        return metrics
    }
    
    // MARK: - Streaming API
    func setStreamingEnabled(_ enabled: Bool) {
        enableStreaming = enabled
    }
    
    func setChunkSize(_ size: Int) {
        chunkSize = max(10, min(size, 200))
    }
    
    func processStreamingText(_ text: String) {
        guard enableStreaming else { return }
        
        streamingBuffer += text + " "
        
        if streamingBuffer.count >= chunkSize {
            processStreamingChunk()
        }
    }
    
    private func processStreamingChunk() {
        guard !streamingBuffer.isEmpty else { return }
        
        let chunk = streamingBuffer
        streamingBuffer = ""
        metrics.streamingChunks += 1
        
        let startTime = CACurrentMediaTime()
        
        Task {
            do {
                let result = try await aiTranslationService.translate(
                    input: chunk,
                    direction: .humanToDog
                )
                
                let endTime = CACurrentMediaTime()
                let latency = endTime - startTime
                metrics.lastChunkLatency = latency
                
                updateMetrics(latency: latency, success: true)
                
                lastPartialTranslation = result.translatedText
                delegate?.realTranslationController(self, didTranslatePartial: chunk, toPartialTranslation: result.translatedText)
                
                synthesizeAndPlayDogVocalization(result.translatedText)
                
            } catch {
                updateMetrics(latency: CACurrentMediaTime() - startTime, success: false)
                delegate?.realTranslationController(self, didFailWithError: error)
            }
        }
    }
    
    // MARK: - Continuous Mode
    func setContinuousMode(_ enabled: Bool) {
        isContinuousMode = enabled
        
        if enabled && isTranslating {
            startContinuousMode()
        } else {
            stopContinuousMode()
        }
    }
    
    func isContinuousModeEnabled() -> Bool {
        return isContinuousMode
    }
    
    private func startContinuousMode() {
        continuousTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.continuousModeTick()
        }
    }
    
    private func stopContinuousMode() {
        continuousTimer?.invalidate()
        continuousTimer = nil
    }
    
    private func continuousModeTick() {
        guard isTranslating else { return }
    }
    
    // MARK: - AI Translation
    func translateWithAI(input: String, direction: TranslationDirection = .humanToDog) async throws -> AITranslationResult {
        let startTime = CACurrentMediaTime()
        
        let result = try await aiTranslationService.translate(input: input, direction: direction)
        
        let latency = CACurrentMediaTime() - startTime
        updateMetrics(latency: latency, success: true)
        
        return result
    }
    
    // MARK: - Latency Threshold
    func setLatencyThreshold(_ threshold: TimeInterval) {
        latencyThreshold = max(0.1, threshold)
    }
    
    func getLatencyThreshold() -> TimeInterval {
        return latencyThreshold
    }
    
    // MARK: - Private Methods
    private func setupDelegates() {
        // Audio capture delegate
        audioCapture.delegate = self
        
        // Speech recognition delegate
        speechRecognition.delegate = self
        
        // Audio playback delegate
        audioPlayback.delegate = self
    }
    
    private func resetMetrics() {
        metrics = TranslationMetrics(
            lastTranslationLatency: 0,
            averageLatency: 0,
            bufferProcessingTime: 0,
            translationSuccessRate: 0,
            totalTranslations: 0,
            failedTranslations: 0
        )
    }
    
    private func updateMetrics(latency: TimeInterval, success: Bool) {
        metrics.lastTranslationLatency = latency
        metrics.totalTranslations += 1
        
        if !success {
            metrics.failedTranslations += 1
        }
        
        // Calculate average latency
        if metrics.totalTranslations > 0 {
            metrics.averageLatency = (metrics.averageLatency * Double(metrics.totalTranslations - 1) + latency) / Double(metrics.totalTranslations)
        }
        
        // Calculate success rate
        if metrics.totalTranslations > 0 {
            metrics.translationSuccessRate = 1.0 - Double(metrics.failedTranslations) / Double(metrics.totalTranslations)
        }
        
        delegate?.realTranslationController(self, didUpdateMetrics: metrics)
    }
    
    private func transitionState(_ newState: TranslationState) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        let oldState = currentState
        currentState = newState
        
        delegate?.realTranslationController(self, didTransitionFrom: oldState, to: newState)
    }
}

// MARK: - RealTranslationControllerDelegate

protocol RealTranslationControllerDelegate: AnyObject {
    func realTranslationControllerDidStart(_ controller: RealTranslationController)
    func realTranslationControllerDidStop(_ controller: RealTranslationController, totalTime: TimeInterval)
    func realTranslationControllerDidPause(_ controller: RealTranslationController)
    func realTranslationControllerDidResume(_ controller: RealTranslationController)
    func realTranslationController(_ controller: RealTranslationController, didUpdateMetrics metrics: RealTranslationController.TranslationMetrics)
    func realTranslationController(_ controller: RealTranslationController, didTransitionFrom oldState: RealTranslationController.TranslationState, to newState: RealTranslationController.TranslationState)
    func realTranslationController(_ controller: RealTranslationController, didTranslate text: String, toDogTranslation: String)
    func realTranslationController(_ controller: RealTranslationController, didTranslatePartial text: String, toPartialTranslation: String)
    func realTranslationController(_ controller: RealTranslationController, didRecognizePartialSpeech text: String)
    func realTranslationController(_ controller: RealTranslationController, didFailWithError error: Error)
    func realTranslationController(_ controller: RealTranslationController, didPlayAudio duration: TimeInterval)
    func realTranslationController(_ controller: RealTranslationController, didUpdateAudioLevel level: Float)
}

// MARK: - RealTranslationController Errors

enum RealTranslationError: Error, LocalizedError {
    case alreadyTranslating
    case notTranslating
    case notPaused
    case audioCaptureFailed
    case speechRecognitionFailed
    case translationFailed
    case audioPlaybackFailed
    case latencyThresholdExceeded
    
    var errorDescription: String? {
        switch self {
        case .alreadyTranslating:
            return "Already translating"
        case .notTranslating:
            return "Not currently translating"
        case .notPaused:
            return "Not currently paused"
        case .audioCaptureFailed:
            return "Audio capture failed"
        case .speechRecognitionFailed:
            return "Speech recognition failed"
        case .translationFailed:
            return "Translation failed"
        case .audioPlaybackFailed:
            return "Audio playback failed"
        case .latencyThresholdExceeded:
            return "Translation latency exceeded threshold"
        }
    }
}

// MARK: - RealTranslationController Extensions

extension RealTranslationController: AudioCaptureDelegate {
    func audioCaptureDidStart(_ capture: AudioCapture) {
        // State transition handled by startTranslation()
    }
    
    func audioCaptureDidStop(_ capture: AudioCapture) {
        // State transition handled by stopTranslation()
    }
    
    func audioCapture(_ capture: AudioCapture, didReceiveBuffer buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        // Pass buffer to speech recognition
        speechRecognition.processAudioBuffer(buffer, at: time)
    }
    
    func audioCapture(_ capture: AudioCapture, didFailWithError error: Error) {
        delegate?.realTranslationController(self, didFailWithError: error)
    }
    
    func audioCapture(_ capture: AudioCapture, didUpdateAudioLevel level: Float) {
        delegate?.realTranslationController(self, didUpdateAudioLevel: level)
    }
}

extension RealTranslationController: SpeechRecognitionDelegate {
    func speechRecognitionDidStart(_ recognition: SpeechRecognition) {
        transitionState(.recognizing)
    }
    
    func speechRecognitionDidStop(_ recognition: SpeechRecognition) {
        // State transition handled by stopTranslation()
    }
    
    func speechRecognition(_ recognition: SpeechRecognition, didRecognizeSpeech text: String) {
        // Handle partial recognition results
        delegate?.realTranslationController(self, didRecognizePartialSpeech: text)
    }
    
    func speechRecognition(_ recognition: SpeechRecognition, didCompleteFinalRecognition text: String) {
        // Perform translation
        let startTime = CACurrentMediaTime()
        
        translationEngine.translateHumanToDog(text) { [weak self] result in
            guard let self = self else { return }
            
            let endTime = CACurrentMediaTime()
            let latency = endTime - startTime
            
            switch result {
            case .success(let dogTranslation):
                // Update metrics
                self.updateMetrics(latency: latency, success: true)
                
                // Notify delegate
                self.delegate?.realTranslationController(self, didTranslate: text, toDogTranslation: dogTranslation)
                
                // Synthesize dog vocalization
                self.synthesizeAndPlayDogVocalization(dogTranslation)
                
            case .failure(let error):
                // Update metrics
                self.updateMetrics(latency: latency, success: false)
                
                // Notify delegate
                self.delegate?.realTranslationController(self, didFailWithError: error)
            }
        }
    }
    
    func speechRecognition(_ recognition: SpeechRecognition, didFailWithError error: Error) {
        delegate?.realTranslationController(self, didFailWithError: error)
    }
    
    func speechRecognition(_ recognition: SpeechRecognition, availabilityDidChange available: Bool) {
        // Handle availability changes
    }
}

extension RealTranslationController: AudioPlaybackDelegate {
    func audioPlaybackDidStart(_ playback: AudioPlayback) {
        transitionState(.playing)
    }
    
    func audioPlaybackDidStop(_ playback: AudioPlayback) {
        transitionState(.idle)
    }
    
    func audioPlaybackDidPause(_ playback: AudioPlayback) {
        // Handle pause if needed
    }
    
    func audioPlaybackDidResume(_ playback: AudioPlayback) {
        // Handle resume if needed
    }
    
    func audioPlayback(_ playback: AudioPlayback, didFinishPlaying finished: Bool) {
        if finished {
            transitionState(.idle)
        }
    }
    
    func audioPlayback(_ playback: AudioPlayback, didChangeVolume volume: Float) {
        // Handle volume changes if needed
    }
    
    func audioPlayback(_ playback: AudioPlayback, didFailWithError error: Error) {
        delegate?.realTranslationController(self, didFailWithError: error)
    }
}

// MARK: - Private Methods

extension RealTranslationController {
    private func synthesizeAndPlayDogVocalization(_ dogTranslation: String) {
        // Synthesize dog vocalization audio
        translationBridge.synthesizeDogVocalization(from: dogTranslation) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let audioData):
                do {
                    try self.audioPlayback.playAudio(audioData)
                    if let duration = self.audioPlayback.currentAudioDuration {
                        self.delegate?.realTranslationController(self, didPlayAudio: duration)
                    }
                } catch {
                    self.delegate?.realTranslationController(self, didFailWithError: error)
                }
            case .failure(let error):
                self.delegate?.realTranslationController(self, didFailWithError: error)
            }
        }
    }
    
    private func didUpdateAudioLevel(_ level: Float) {
        delegate?.realTranslationController(self, didUpdateAudioLevel: level)
    }
}