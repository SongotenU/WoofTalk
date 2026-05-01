import WidgetKit
import SwiftUI

struct TranslationEntry: TimelineEntry {
    let date: Date
    let humanText: String
    let dogTranslation: String
}

struct WoofTalkWidgetProvider: TimelineProvider {
    typealias Entry = TranslationEntry

    func placeholder(in context: Context) -> TranslationEntry {
        TranslationEntry(date: Date(), humanText: "Hello", dogTranslation: "Woof woof!")
    }

    func getSnapshot(in context: Context, completion: @escaping (TranslationEntry) -> Void) {
        let entry = TranslationEntry(date: Date(), humanText: "Hello", dogTranslation: "Woof woof!")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TranslationEntry>) -> Void) {
        let entries = loadRecentTranslations()
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func loadRecentTranslations() -> [TranslationEntry] {
        let defaults = UserDefaults(suiteName: "group.vandopha.WoofTalk") ?? UserDefaults.standard
        guard let data = defaults.data(forKey: "recentTranslations"),
              let translations = try? JSONDecoder().decode([RecentTranslation].self, from: data) else {
            return [TranslationEntry(date: Date(), humanText: "No recent translations", dogTranslation: "")]
        }
        return translations.prefix(3).map {
            TranslationEntry(date: $0.timestamp, humanText: $0.humanText, dogTranslation: $0.dogTranslation)
        }
    }
}

struct WoofTalkWidgetEntryView: View {
    var entry: WoofTalkWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dog.fill")
                    .foregroundColor(.orange)
                Text("Recent Translation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(entry.humanText)
                .font(.headline)
                .lineLimit(1)
            Text(entry.dogTranslation)
                .font(.subheadline)
                .foregroundColor(.orange)
                .lineLimit(1)
        }
        .padding()
    }
}

struct WoofTalkWidget: Widget {
    let kind: String = "WoofTalkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WoofTalkWidgetProvider()) { entry in
            WoofTalkWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("WoofTalk Translation")
        .description("Shows your recent dog translations.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RecentTranslation: Codable {
    let humanText: String
    let dogTranslation: String
    let timestamp: Date
}

struct WoofTalkWidget_Previews: PreviewProvider {
    static var previews: some View {
        WoofTalkWidgetEntryView(entry: TranslationEntry(date: Date(), humanText: "Hello", dogTranslation: "Woof woof!"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
