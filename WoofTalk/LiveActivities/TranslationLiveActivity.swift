import ActivityKit
import SwiftUI

struct TranslationLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TranslationActivityAttributes.self) { context in
            TranslationLiveActivityView(context: context)
        }
    }
}

struct TranslationLiveActivityView: View {
    let context: ActivityViewContext<TranslationActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "mic.fill")
                .foregroundColor(.orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Translating...")
                    .font(.headline)
                Text(context.attributes.sourceLanguage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let translation = context.state.currentTranslation {
                Text(translation)
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .lineLimit(1)
            }
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground))
        .activitySystemActionForegroundColor(Color.orange)
    }
}

struct TranslationActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentTranslation: String?
    }

    var sourceLanguage: String
    var targetLanguage: String
}

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<TranslationActivityAttributes>?

    func startLiveActivity(sourceLanguage: String, targetLanguage: String) {
        let attributes = TranslationActivityAttributes(
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage
        )
        let contentState = TranslationActivityAttributes.ContentState(currentTranslation: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
        }
    }

    func updateLiveActivity(translation: String) {
        guard let activity = currentActivity else { return }
        let contentState = TranslationActivityAttributes.ContentState(currentTranslation: translation)

        Task {
            await activity.update(using: contentState)
        }
    }

    func endLiveActivity() {
        guard let activity = currentActivity else { return }
        let contentState = TranslationActivityAttributes.ContentState(currentTranslation: nil)

        Task {
            await activity.end(using: contentState, dismissalPolicy: .default)
            currentActivity = nil
        }
    }
}
