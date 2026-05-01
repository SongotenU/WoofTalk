import Intents

class WoofTalkIntentHandler: INExtension, INStartAudioTravelIntentHandling {
    func handle(intent: INStartAudioTravelIntent, completion: @escaping (INStartAudioTravelIntentResponse) -> Void) {
        let response = INStartAudioTravelIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }

    func confirm(intent: INStartAudioTravelIntent, completion: @escaping (INStartAudioTravelIntentResponse) -> Void) {
        let response = INStartAudioTravelIntentResponse(code: .ready, userActivity: nil)
        completion(response)
    }

    func resolveTravelDestination(for intent: INStartAudioTravelIntent, with completion: @escaping (INAudioDestinationResolutionResult) -> Void) {
        if let destination = intent.travelDestination {
            completion(INAudioDestinationResolutionResult.success(with: destination))
        } else {
            completion(INAudioDestinationResolutionResult.needsValue())
        }
    }
}
