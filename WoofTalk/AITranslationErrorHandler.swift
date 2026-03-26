import Foundation

final class AITranslationErrorHandler {
    static let shared = AITranslationErrorHandler()
    
    private var errorLog: [TranslationErrorLog] = []
    private let maxLogSize = 100
    
    private init() {}
    
    func handleError(_ error: Error, context: TranslationContext) -> ErrorAction {
        let logEntry = TranslationErrorLog(
            error: error,
            context: context,
            timestamp: Date()
        )
        
        addToLog(logEntry)
        
        if let aiError = error as? AITranslationError {
            return actionForError(aiError, context: context)
        }
        
        return .fallbackToRuleBased
    }
    
    private func actionForError(_ error: AITranslationError, context: TranslationContext) -> ErrorAction {
        switch error {
        case .modelNotLoaded, .modelUnavailable:
            return .fallbackToRuleBased
            
        case .modelLoadFailed:
            return .fallbackToRuleBased
            
        case .translationFailed:
            return .fallbackToRuleBased
            
        case .invalidInput:
            return .retryWithRuleBased
            
        case .inferenceTimeout:
            return .retryWithRuleBased
        }
    }
    
    private func addToLog(_ entry: TranslationErrorLog) {
        errorLog.append(entry)
        if errorLog.count > maxLogSize {
            errorLog.removeFirst()
        }
    }
    
    func getRecentErrors(limit: Int = 10) -> [TranslationErrorLog] {
        return Array(errorLog.suffix(limit))
    }
    
    func clearLog() {
        errorLog.removeAll()
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

struct TranslationErrorLog {
    let error: Error
    let context: TranslationContext
    let timestamp: Date
    
    var description: String {
        return "[\(timestamp)] \(error.localizedDescription) - \(context.direction)"
    }
}