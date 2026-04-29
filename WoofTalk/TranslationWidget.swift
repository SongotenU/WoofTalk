import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct TranslationEntry: TimelineEntry {
    let date: Date
    let translationCount: Int
    let lastTranslation: String
}

// MARK: - Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TranslationEntry {
        TranslationEntry(date: Date(), translationCount: 5, lastTranslation: "Woof!")
    }

    func getSnapshot(in context: Context, completion: @escaping (TranslationEntry) -> Void) {
        let entry = TranslationEntry(date: Date(), translationCount: fetchTranslationCount(), lastTranslation: fetchLastTranslation())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TranslationEntry>) -> Void) {
        let entry = TranslationEntry(date: Date(), translationCount: fetchTranslationCount(), lastTranslation: fetchLastTranslation())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60)))
        completion(timeline)
    }

    private func fetchTranslationCount() -> Int {
        // Fetch from CoreData or UserDefaults
        UserDefaults.standard.integer(forKey: "translationCount")
    }

    private func fetchLastTranslation() -> String {
        UserDefaults.standard.string(forKey: "lastTranslation") ?? "No recent translations"
    }
}

// MARK: - Widget View
struct TranslationWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Translations")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(entry.translationCount)")
                .font(.title)
                .bold()
            Text(entry.lastTranslation)
                .font(.caption2)
                .lineLimit(1)
            Spacer()
            Link(destination: URL(string: "wooftalk://translate")!) {
                Text("Quick Translate")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding()
    }
}

// MARK: - Widget Definition
struct TranslationStatsWidget: Widget {
    let kind: String = "TranslationStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TranslationWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Translation Stats")
        .description("Shows recent translation count and quick translate shortcut.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
