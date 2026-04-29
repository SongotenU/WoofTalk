import AVFoundation

final class AudioSessionManager {
    private let audioSession = AVAudioSession.sharedInstance()

    func configureSession() throws {
        do {
            try audioSession.setCategory(.playAndRecord,
                                          options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try audioSession.setMode(.measurement)
            try audioSession.setActive(true)
            try audioSession.setPreferredSampleRate(AudioFormats.standardSampleRate)
            try audioSession.setPreferredIOBufferDuration(0.005)
        } catch {
            throw AudioEngineError.audioSessionConfigurationFailed
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
}
