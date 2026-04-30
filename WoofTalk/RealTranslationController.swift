// MARK: - RealTranslationController

import Foundation

final class RealTranslationController {

    private let translationEngine = TranslationEngine()
    private var isTranslating = false
    private let dailyLimit = 3
    private let dailyCountKey = "RealTranslationController.dailyCount"
    private let dailyCountDateKey = "RealTranslationController.dailyCountDate"

    weak var delegate: RealTranslationControllerDelegate?

    private var dailyTranslationsUsed: Int {
        let lastDate = UserDefaults.standard.object(forKey: dailyCountDateKey) as? Date ?? .distantPast
        if !Calendar.current.isDateInToday(lastDate) {
            // Reset counter if it's a new day
            UserDefaults.standard.set(0, forKey: dailyCountKey)
            UserDefaults.standard.set(Date(), forKey: dailyCountDateKey)
            return 0
        }
        return UserDefaults.standard.integer(forKey: dailyCountKey)
    }

    private func incrementDailyCount() {
        let current = dailyTranslationsUsed
        UserDefaults.standard.set(current + 1, forKey: dailyCountKey)
    }

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
        // Check daily limit for free users
        let entitlement = EntitlementManager.shared
        guard entitlement.isPremium || dailyTranslationsUsed < dailyLimit else {
            delegate?.realTranslationController(self, didFailWithError: RealTranslationError.dailyLimitReached)
            return
        }

        do {
            let result = try translationEngine.translate(text, direction: direction)
            if !entitlement.isPremium {
                incrementDailyCount()
            }
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
    case dailyLimitReached

    var errorDescription: String? {
        switch self {
        case .alreadyTranslating: return "Already translating"
        case .dailyLimitReached: return "Daily translation limit reached. Upgrade to premium for unlimited translations."
        }
    }
}
