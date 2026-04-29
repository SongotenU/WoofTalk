import Foundation

final class AITranslationErrorHandler {
    static let shared = AITranslationErrorHandler()
    private init() {}

    func handleError(_ error: Error, context: TranslationContext) -> ErrorAction {
        guard let aiError = error as? AITranslationError else {
            return .fallbackToRuleBased
        }
        switch aiError {
        case .modelNotLoaded, .modelUnavailable, .modelLoadFailed, .translationFailed:
            return .fallbackToRuleBased
        case .invalidInput, .inferenceTimeout:
            return .retryWithRuleBased
        }
    }
}

enum ErrorAction {
    case fallbackToRuleBased
    case retryWithRuleBased
    case showErrorToUser
    case retry
}

struct TranslationContext {
    let input: String
    let direction: TranslationDirection
    let mode: TranslationMode
}
