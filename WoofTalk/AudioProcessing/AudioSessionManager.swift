// MARK: - AudioSessionManager

import AVFoundation

/// Manages audio session configuration for optimal audio processing
final class AudioSessionManager {
    
    // MARK: Properties
    private var audioSession = AVAudioSession.sharedInstance()
    
    // MARK: Public Methods
    func configureSession() throws {
        do {
            // Configure for low-latency audio processing
            try audioSession.setCategory(.playAndRecord, 
                                          options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try audioSession.setMode(.measurement)
            try audioSession.setActive(true)
            
            // Set preferred sample rate and buffer duration
            let preferredSampleRate = AudioFormats.preferredSampleRate
            let preferredIOBufferDuration = AudioFormats.preferredBufferDuration
            
            try audioSession.setPreferredSampleRate(preferredSampleRate)
            try audioSession.setPreferredIOBufferDuration(preferredIOBufferDuration)
            
        } catch {
            throw AudioEngineError.audioSessionConfigurationFailed
        }
    }
    
    func deactivateSession() {
        try? audioSession.setActive(false)
    }
    
    // MARK: State Monitoring
    var currentSampleRate: Double {
        return audioSession.sampleRate
    }
    
    var currentBufferDuration: Double {
        return audioSession.ioBufferDuration
    }
    
    var isAudioInputAvailable: Bool {
        return audioSession.isInputAvailable
    }
    
    var availableInputs: [AVAudioSession.Port] {
        return audioSession.availableInputs?.map { $0.portType } ?? []
    }
    
    // MARK: Permission Handling
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    var microphonePermissionStatus: AVAudioSession.RecordPermission {
        return audioSession.recordPermission
    }
}

// MARK: - AudioSessionManagerDelegate

protocol AudioSessionManagerDelegate: AnyObject {
    func audioSessionManager(_ manager: AudioSessionManager, didChangeInputAvailability available: Bool)
    func audioSessionManager(_ manager: AudioSessionManager, didChangeSampleRate sampleRate: Double)
    func audioSessionManager(_ manager: AudioSessionManager, didChangeBufferDuration bufferDuration: Double)
}

// MARK: - AudioSession Errors

enum AudioSessionError: Error, LocalizedError {
    case microphonePermissionDenied
    case audioInputUnavailable
    case audioSessionActivationFailed
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission denied"
        case .audioInputUnavailable:
            return "Audio input unavailable"
        case .audioSessionActivationFailed:
            return "Audio session activation failed"
        }
    }
}