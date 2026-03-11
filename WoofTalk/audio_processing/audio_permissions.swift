//
//  audio_permissions.swift
//  WoofTalk
//
//  Created by vandopha on 11/3/26.
//

import AVFoundation
import Speech

enum AudioPermissionStatus: String {
    case granted = "granted"
    case denied = "denied"
    case notDetermined = "notDetermined"
    case restricted = "restricted"
}

class AudioPermissionManager {
    static func checkMicrophonePermission() -> AudioPermissionStatus {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    static func requestMicrophonePermission(completion: @escaping (AudioPermissionStatus) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted ? .granted : .denied)
            }
        }
    }
    
    static func checkSpeechPermission() -> AudioPermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
    
    static func requestSpeechPermission(completion: @escaping (AudioPermissionStatus) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status.toPermissionStatus())
            }
        }
    }
    
    static func checkAllPermissions() -> [String: AudioPermissionStatus] {
        return [
            "microphone": checkMicrophonePermission(),
            "speech": checkSpeechPermission()
        ]
    }
    
    static func requestAllPermissions(microphoneCompletion: @escaping (AudioPermissionStatus) -> Void,
                                     speechCompletion: @escaping (AudioPermissionStatus) -> Void) {
        let group = DispatchGroup()
        var microphoneStatus: AudioPermissionStatus = .notDetermined
        var speechStatus: AudioPermissionStatus = .notDetermined
        
        group.enter()
        requestMicrophonePermission { status in
            microphoneStatus = status
            group.leave()
        }
        
        group.enter()
        requestSpeechPermission { status in
            speechStatus = status
            group.leave()
        }
        
        group.notify(queue: .main) {
            microphoneCompletion(microphoneStatus)
            speechCompletion(speechStatus)
        }
    }
    
    static func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
    }
    
    static func getPermissionExplanation(for status: AudioPermissionStatus) -> String {
        switch status {
        case .granted:
            return "Microphone access is granted."
        case .denied:
            return "Microphone access was denied. Please enable it in Settings > Privacy > Microphone."
        case .notDetermined:
            return "Microphone access has not been requested yet."
        case .restricted:
            return "Microphone access is restricted by parental controls or device policy."
        }
    }
}

extension SFSpeechRecognizerAuthorizationStatus {
    func toPermissionStatus() -> AudioPermissionStatus {
        switch self {
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }
}