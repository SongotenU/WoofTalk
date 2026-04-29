import AVFoundation

final class AudioSessionManager {
    private let audioSession = AVAudioSession.sharedInstance()

    func configureSession() throws {
        do {
            try audioSession.setCategory(.playAndRecord,
                                          options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try audioSession.setMode(.voiceChat)
            try audioSession.setActive(true)
            try audioSession.setPreferredSampleRate(AudioFormats.standardSampleRate)
            try audioSession.setPreferredIOBufferDuration(0.005)
        } catch {
            throw AudioEngineError.audioSessionConfigurationFailed
        }
    }

    /// Configure session for background audio recording
    func configureForBackgroundAudio() throws {
        do {
            try audioSession.setCategory(.playAndRecord,
                                          options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try audioSession.setMode(.voiceChat)
            try audioSession.setActive(true, options: [])
        } catch {
            throw AudioEngineError.audioSessionConfigurationFailed
        }
    }

    /// Handle audio session interruption
    func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // Interruption began, audio session deactivated
            break
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                try? audioSession.setActive(true)
            }
        @unknown default:
            break
        }
    }

    func deactivateSession() {
        try? audioSession.setActive(false)
    }

    var currentSampleRate: Double { audioSession.sampleRate }
    var currentBufferDuration: Double { audioSession.ioBufferDuration }
    var isAudioInputAvailable: Bool { audioSession.isInputAvailable }

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        audioSession.requestRecordPermission { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    var microphonePermissionStatus: AVAudioSession.RecordPermission {
        audioSession.recordPermission
    }

    // MARK: - Audio Input Source Selection

    /// Get available audio input sources
    var availableInputSources: [AudioInputSource] {
        let inputs = audioSession.availableInputs ?? []
        return inputs.map { input in
            AudioInputSource(
                uid: input.uid,
                portType: input.portType.rawValue,
                portName: input.portName,
                isCurrentlySelected: audioSession.currentRoute.inputs.contains { $0.uid == input.uid }
            )
        }
    }

    /// Get current input source
    var currentInputSource: AudioInputSource? {
        audioSession.currentRoute.inputs.first.map {
            AudioInputSource(
                uid: $0.uid,
                portType: $0.portType.rawValue,
                portName: $0.portName,
                isCurrentlySelected: true
            )
        }
    }

    /// Select audio input source by UID
    func selectInputSource(uid: String) throws {
        guard let input = audioSession.availableInputs?.first(where: { $0.uid == uid }) else {
            throw AudioSessionError.inputSourceNotFound
        }
        do {
            try audioSession.setPreferredInput(input)
        } catch {
            throw AudioSessionError.failedToSelectInputSource
        }
    }

    /// Get input source type description
    func inputSourceDescription(for portType: String) -> String {
        switch portType {
        case AVAudioSession.Port.builtInMic.rawValue: return "Built-in Microphone"
        case AVAudioSession.Port.bluetoothHFP.rawValue: return "Bluetooth Headset"
        case AVAudioSession.Port.bluetoothLE.rawValue: return "Bluetooth LE"
        case AVAudioSession.Port.airPods.rawValue: return "AirPods"
        case AVAudioSession.Port.headsetMic.rawValue: return "Wired Headset"
        case AVAudioSession.Port.lineIn.rawValue: return "Line In"
        default: return portType
        }
    }
}

struct AudioInputSource: Identifiable {
    let uid: String
    let portType: String
    let portName: String
    let isCurrentlySelected: Bool

    var id: String { uid }
    var displayName: String { portName }
}

enum AudioSessionError: Error, LocalizedError {
    case inputSourceNotFound
    case failedToSelectInputSource

    var errorDescription: String? {
        switch self {
        case .inputSourceNotFound: return "Audio input source not found"
        case .failedToSelectInputSource: return "Failed to select audio input source"
        }
    }
}
