import Foundation
import SQLite3

final class VocabularyDatabase {
    private let databaseFileName = "wooftalk_vocabulary.sqlite"
    private var database: OpaquePointer?

    private init() {
        openDatabase()
        createTables()
        populateDatabase()
    }

    deinit { closeDatabase() }

    func lookupHumanToDog(_ text: String) -> String {
        !text.isEmpty ? lookupHumanToDogInternal(normalizeText(text)) : ""
    }

    func lookupDogToHuman(_ text: String) -> String {
        !text.isEmpty ? lookupDogToHumanInternal(normalizeText(text)) : ""
    }

    private func openDatabase() {
        let fileURL = getDatabaseFileURL()
        if sqlite3_open(fileURL.path, &database) != SQLITE_OK {
            database = nil
        }
    }

    private func closeDatabase() {
        if let db = database { sqlite3_close(db); database = nil }
    }

    private func createTables() {
        executeQuery("""
            CREATE TABLE IF NOT EXISTS vocabulary (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                human_text TEXT NOT NULL,
                dog_text TEXT NOT NULL
            );
        """)
        executeQuery("CREATE INDEX IF NOT EXISTS idx_human_text ON vocabulary (human_text);")
        executeQuery("CREATE INDEX IF NOT EXISTS idx_dog_text ON vocabulary (dog_text);")
    }

    private func populateDatabase() {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(database, "SELECT COUNT(*) FROM vocabulary;", -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW, sqlite3_column_int(stmt, 0) == 0 {
            populateInitialVocabulary()
        }
    }

    private func populateInitialVocabulary() {
        let entries = [
            ("sit", "woof woof woof"),
            ("stay", "woof woof woof woof"),
            ("come", "woof woof woof woof woof"),
            ("no", "woof woof woof woof woof woof woof"),
            ("yes", "woof woof woof woof woof woof woof woof"),
            ("good boy", "woof woof woof woof woof woof woof woof woof woof"),
        ]
        for (human, dog) in entries {
            insertVocabulary(humanText: human, dogText: dog)
        }
    }

    private func insertVocabulary(humanText: String, dogText: String) {
        var stmt: OpaquePointer?
        let query = "INSERT INTO vocabulary (human_text, dog_text) VALUES (?, ?);"
        guard sqlite3_prepare_v2(database, query, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (humanText as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (dogText as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
    }

    private func lookupHumanToDogInternal(_ text: String) -> String {
        querySingleValue("SELECT dog_text FROM vocabulary WHERE human_text = ? LIMIT 1;", value: text)
    }

    private func lookupDogToHumanInternal(_ text: String) -> String {
        querySingleValue("SELECT human_text FROM vocabulary WHERE dog_text = ? LIMIT 1;", value: text)
    }

    private func querySingleValue(_ query: String, value: String) -> String {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &stmt, nil) == SQLITE_OK else { return "" }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (value as NSString).utf8String, -1, nil)
        if sqlite3_step(stmt) == SQLITE_ROW {
            return String(cString: sqlite3_column_text(stmt, 0))
        }
        return ""
    }

    private func normalizeText(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func getDatabaseFileURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(databaseFileName)
    }

    private func executeQuery(_ query: String) {
        sqlite3_exec(database, (query as NSString).utf8String, nil, nil, nil)
    }
}
