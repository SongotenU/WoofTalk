import Foundation
import WatchKit

enum HapticPattern {
    case happy
    case alert
    case playful
    case distressed
    case success
    case error
}

final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    func play(_ pattern: HapticPattern) {
        switch pattern {
        case .happy:
            WKInterfaceDevice.current().play(.success)
        case .alert:
            WKInterfaceDevice.current().play(.failure)
        case .playful:
            WKInterfaceDevice.current().play(.click)
        case .distressed:
            WKInterfaceDevice.current().play(.retry)
        case .success:
            WKInterfaceDevice.current().play(.success)
        case .error:
            WKInterfaceDevice.current().play(.failure)
        }
    }

    func playForTranslation(_ text: String) {
        let lower = text.lowercased()
        if lower.contains("happy") || lower.contains("play") || lower.contains("good") {
            play(.happy)
        } else if lower.contains("alert") || lower.contains("watch") || lower.contains("danger") {
            play(.alert)
        } else if lower.contains("treat") || lower.contains("ball") || lower.contains("fetch") {
            play(.playful)
        } else if lower.contains("hurt") || lower.contains("pain") || lower.contains("scared") {
            play(.distressed)
        } else {
            play(.success)
        }
    }
}
