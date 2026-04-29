import Intents

/// Siri Intent for "Translate to Dog" shortcut
@available(iOS 14.0, *)
class TranslateIntent: INIntent {
    @NSManaged public var sourceText: String?
    @NSManaged public var targetLanguage: String?
}

/// Intent Handler for TranslateIntent
@available(iOS 14.0, *)
class TranslateIntentHandler: NSObject {
    func handle(intent: TranslateIntent, completion: @escaping (TranslateIntentResponse) -> Void) {
        guard let text = intent.sourceText, !text.isEmpty else {
            let response = TranslateIntentResponse(code: .failure, userActivity: nil)
            completion(response)
            return
        }
        let targetLang = intent.targetLanguage ?? "Dog"
        // Trigger translation
        NotificationCenter.default.post(
            name: .init("SiriTranslate"),
            object: nil,
            userInfo: ["text": text, "language": targetLang]
        )
        let response = TranslateIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }

    func confirm(intent: TranslateIntent, completion: @escaping (TranslateIntentResponse) -> Void) {
        let response = TranslateIntentResponse(code: .ready, userActivity: nil)
        completion(response)
    }
}

/// Response object for TranslateIntent
@available(iOS 14.0, *)
class TranslateIntentResponse: INIntentResponse {
    init(code: ResponseCode, userActivity: NSUserActivity?) {
        super.init()
        self.code = code.rawValue as NSNumber
        self.userActivity = userActivity
    }

    enum ResponseCode: Int {
        case success = 0
        case failure = 1
        case ready = 2
    }
}
