import Foundation
import WatchConnectivity

struct WatchTranslation: Codable, Identifiable {
    let id: UUID
    let input: String
    let translated: String
    let direction: String
    let timestamp: Date

    init(id: UUID = UUID(), input: String, translated: String, direction: String, timestamp: Date = Date()) {
        self.id = id
        self.input = input
        self.translated = translated
        self.direction = direction
        self.timestamp = timestamp
    }
}

final class WatchTranslationStore {
    static let shared = WatchTranslationStore()
    private let storageKey = "watch_translations"

    private init() {}

    func save(_ translation: WatchTranslation) {
        var all = fetchAll()
        all.insert(translation, at: 0)
        if all.count > 50 { all = Array(all.prefix(50)) }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func fetchAll() -> [WatchTranslation] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WatchTranslation].self, from: data) else {
            return []
        }
        return decoded
    }

    func lastTranslation() -> WatchTranslation? {
        fetchAll().first
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
