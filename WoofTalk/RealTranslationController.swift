// MARK: - RealTranslationController

import Foundation

final class RealTranslationController {

    private let translationEngine = TranslationEngine()
    private var isTranslating = false

    weak var delegate: RealTranslationControllerDelegate?

    func startTranslation() throws {
        guard !isTranslating else { throw RealTranslationError.alreadyTranslating }
        isTranslating = true
        delegate?.realTranslationControllerDidStart(self)
    }

    func stopTranslation() {
        guard isTranslating else { return }
        isTranslating = false
        delegate?.realTranslationControllerDidStop(self, totalTime: 0)
    }

    func translate(text: String, direction: TranslationDirection = .humanToDog) {
        do {
            let result = try translationEngine.translate(text, direction: direction)
            delegate?.realTranslationController(self, didTranslate: text, toDogTranslation: result)
        } catch {
            delegate?.realTranslationController(self, didFailWithError: error)
        }
    }
}

// MARK: - RealTranslationControllerDelegate

protocol RealTranslationControllerDelegate: AnyObject {
    func realTranslationControllerDidStart(_ controller: RealTranslationController)
    func realTranslationControllerDidStop(_ controller: RealTranslationController, totalTime: TimeInterval)
    func realTranslationController(_ controller: RealTranslationController, didTranslate text: String, toDogTranslation: String)
    func realTranslationController(_ controller: RealTranslationController, didFailWithError error: Error)
}

// MARK: - RealTranslationError

enum RealTranslationError: Error, LocalizedError {
    case alreadyTranslating

    var errorDescription: String? {
        switch self {
        case .alreadyTranslating: return "Already translating"
        }
    }
}
