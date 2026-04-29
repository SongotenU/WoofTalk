import ActivityKit
import Foundation

/// Live Activity attributes for translation
@available(iOS 16.1, *)
struct TranslationAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phrase: String
        var status: String
        var progress: Double
    }
    var name: String
}

@available(iOS 16.1, *)
struct TranslationLiveActivityView: View {
    let context: ActivityViewContext<TranslationAttributes>

    var body: some View {
        VStack {
            Text(context.state.phrase)
                .font(.headline)
            Text(context.state.status)
                .font(.caption)
            ProgressView(value: context.state.progress)
        }
        .padding()
    }
}

@available(iOS 16.1, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<TranslationAttributes>?

    private init() {}

    func startLiveActivity(phrase: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = TranslationAttributes(name: "WoofTalk Translation")
        let contentState = TranslationAttributes.ContentState(
            phrase: phrase,
            status: "Translating...",
            progress: 0.0
        )
        let content = ActivityContent(state: contentState, staleDate: nil)

        Task {
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                print("Failed to start live activity: \(error)")
            }
        }
    }

    func updateLiveActivity(phrase: String, status: String, progress: Double) {
        guard let activity = currentActivity else { return }
        let contentState = TranslationAttributes.ContentState(
            phrase: phrase,
            status: status,
            progress: progress
        )
        let content = ActivityContent(state: contentState, staleDate: nil)

        Task {
            await activity.update(content)
        }
    }

    func endLiveActivity() {
        guard let activity = currentActivity else { return }
        let contentState = TranslationAttributes.ContentState(
            phrase: "",
            status: "Complete",
            progress: 1.0
        )
        let content = ActivityContent(state: contentState, staleDate: nil)

        Task {
            await activity.end(content, dismissalPolicy: .default)
            currentActivity = nil
        }
    }
}
