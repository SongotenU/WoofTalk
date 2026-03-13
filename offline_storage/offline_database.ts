// MARK: - OfflineDatabase

import Foundation

/// High-level abstraction for phrase operations in offline storage
final class OfflineDatabase {
    
    // MARK: - Public Types
    
    /// Phrase category
    enum PhraseCategory: String, CaseIterable {
        case basicCommands = "basic_commands"
        case greetings = "greetings"
        case questions = "questions"
        case expressions = "expressions"
        case names = "names"
        case other = "other"
        
        static let allCases = [
            basicCommands,
            greetings,
            questions,
            expressions,
            names,
            other
        ]
    }
    
    /// Translation direction
    enum TranslationDirection {
        case humanToDog
        case dogToHuman
    }
    
    /// Phrase structure
    struct Phrase: Codable, Equatable {
        let id: Int?
        let key: String
        let humanText: String
        let dogText: String
        let category: PhraseCategory
        let lastUpdated: Date
        let confidence: Double
        let usageCount: Int
        
        init(
            id: Int? = nil,
            key: String,
            humanText: String,
            dogText: String,
            category: PhraseCategory = .other,
            lastUpdated: Date = Date(),
            confidence: Double = 0.8,
            usageCount: Int = 1
        ) {
            self.id = id
            self.key = key
            self.humanText = humanText
            self.dogText = dogText
            self.category = category
            self.lastUpdated = lastUpdated
            self.confidence = confidence
            self.usageCount = usageCount
        }
        
        var displayText: String {
            switch TranslationEngine.shared.currentDirection {
            case .humanToDog:
                return humanText
            case .dogToHuman:
                return dogText
            }
        }
        
        var translationText: String {
            switch TranslationEngine.shared.currentDirection {
            case .humanToDog:
                return dogText
            case .dogToHuman:
                return humanText
            }
        }
    }
    
    /// Translation result
    struct TranslationResult: Codable {
        let phrase: Phrase
        let confidence: Double
        let isOffline: Bool
        let processingTime: TimeInterval
        let source: TranslationSource
        
        enum TranslationSource: String, Codable {
            case database = "database"
            case fallback = "fallback"
            case cache = "cache"
        }
    }
    
    /// Database statistics
    struct DatabaseStatistics: CustomStringConvertible {
        let totalPhrases: Int
        let categories: [PhraseCategory: Int]
        let averageConfidence: Double
        let lastUpdated: Date?
        let isHealthy: Bool
        
        var description: String {
            let categoriesInfo = categories.map { "\($0.key.rawValue): \($0.value)" }.joined(separator: ", ")
            return "DatabaseStats(total: \(totalPhrases), categories: {\(categoriesInfo)}, avgConfidence: \(String(format: '%.2f', averageConfidence)), lastUpdated: \(String(describing: lastUpdated)), healthy: \(isHealthy))"
        }
    }
    
    // MARK: - Private Properties
    
    static let shared = OfflineDatabase()
    private let sqliteManager = SQLiteManager.shared
    private let databaseQueue = DispatchQueue(label: "com.wooftalk.offline.database.operations")
    private let cache = NSCache<NSString, Phrase>()
    
    // MARK: - Public Methods
    
    /// Initialize database
    func initialize() {
        sqliteManager.initializeDatabase()
    }
    
    /// Add a new phrase to the database
    func addPhrase(_ phrase: Phrase, completion: @escaping (SQLiteManager.DatabaseResult<Int>) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let key = self.generateKey(for: phrase)
            let query = ""
                + "INSERT OR REPLACE INTO phrases (key, human_text, dog_text, category, last_updated, confidence, usage_count) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?);"
            
            let parameters: [Any] = [
                key,
                phrase.humanText,
                phrase.dogText,
                phrase.category.rawValue,
                phrase.lastUpdated,
                phrase.confidence,
                phrase.usageCount
            ]
            
            let result = self.sqliteManager.executeQuery(query, parameters: parameters)
            
            if case .success = result {
                // Get the inserted ID
                let idResult = self.getLastInsertedID()
                completion(idResult)
            } else {
                completion(result.map { _ in 0 })
            }
        }
    }
    
    /// Get a phrase by key
    func getPhrase(forKey key: String, completion: @escaping (SQLiteManager.DatabaseResult<Phrase?>) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let query = "SELECT * FROM phrases WHERE key = ? LIMIT 1;"
            let parameters: [Any] = [key]
            
            let result = self.sqliteManager.queryData(query, parameters: parameters) { statement in
                return self.transformRowToPhrase(statement)
            }
            
            switch result {
            case .success(let phrases):
                completion(.success(phrases.first))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get all phrases in a category
    func getPhrases(inCategory category: PhraseCategory, completion: @escaping (SQLiteManager.DatabaseResult<[Phrase]>) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let query = "SELECT * FROM phrases WHERE category = ? ORDER BY usage_count DESC, confidence DESC;"
            let parameters: [Any] = [category.rawValue]
            
            let result = self.sqliteManager.queryData(query, parameters: parameters) { statement in
                return self.transformRowToPhrase(statement)
            }
            
            completion(result)
        }
    }
    
    /// Get all phrases
    func getAllPhrases(completion: @escaping (SQLiteManager.DatabaseResult<[Phrase]>) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let query = "SELECT * FROM phrases ORDER BY usage_count DESC, confidence DESC;"
            let parameters: [Any] = []
            
            let result = self.sqliteManager.queryData(query, parameters: parameters) { statement in
                return self.transformRowToPhrase(statement)
            }
            
            completion(result)
        }
    }
    
    /// Update a phrase
    func updatePhrase(_ phrase: Phrase, completion: @escaping (SQLiteManager.DatabaseResult<Void>) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let query = ""
                + "UPDATE phrases SET human_text = ?, dog_text = ?, category = ?, last_updated = ?, confidence = ?, usage_count = ? "
                + "WHERE key = ?;"
            
            let parameters: [Any] = [
                phrase.humanText,
                phrase.dogText,
                phrase.category.rawValue,
                phrase.lastUpdated,
                phrase.confidence,
                phrase.usageCount,
                phrase.key
            ]
            
            let result = self.sqliteManager.executeQuery(query, parameters: parameters)
            completion(result)
        }
    }
    
    /// Delete a phrase by key
    func deletePhrase(forKey key: String, completion: @escaping (SQLiteManager.DatabaseResult<Void>) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let query = "DELETE FROM phrases WHERE key = ?;"
            let parameters: [Any] = [key]
            
            let result = self.sqliteManager.executeQuery(query, parameters: parameters)
            completion(result)
        }
    }
    
    /// Search phrases by text
    func searchPhrases(
        query: String,
        completion: @escaping (SQLiteManager.DatabaseResult<[Phrase]>) -> Void
    ) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let searchQuery = ""
                + "SELECT * FROM phrases WHERE human_text LIKE ? OR dog_text LIKE ? "
                + "ORDER BY usage_count DESC, confidence DESC LIMIT 20;"
            
            let searchTerm = "%\(query)%"
            let parameters: [Any] = [searchTerm, searchTerm]
            
            let result = self.sqliteManager.queryData(searchQuery, parameters: parameters) { statement in
                return self.transformRowToPhrase(statement)
            }
            
            completion(result)
        }
    }
    
    /// Get database statistics
    func getStatistics(completion: @escaping (SQLiteManager.DatabaseResult<DatabaseStatistics>) -> Void) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Get total phrases
            let totalQuery = "SELECT COUNT(*) FROM phrases;"
            let totalResult = self.sqliteManager.queryData(totalQuery, parameters: nil) { statement in
                return Int(sqlite3_column_int(statement, 0))
            }
            
            // Get category counts
            let categoriesQuery = "SELECT category, COUNT(*) FROM phrases GROUP BY category;"
            let categoriesResult = self.sqliteManager.queryData(categoriesQuery, parameters: nil) { statement in
                guard let categoryString = String(cString: sqlite3_column_text(statement, 0)) else { return nil }
                guard let category = PhraseCategory(rawValue: categoryString) else { return nil }
                let count = Int(sqlite3_column_int(statement, 1))
                return (category, count)
            }
            
            // Get average confidence
            let avgConfidenceQuery = "SELECT AVG(confidence) FROM phrases;"
            let avgConfidenceResult = self.sqliteManager.queryData(avgConfidenceQuery, parameters: nil) { statement in
                return Double(sqlite3_column_double(statement, 0))
            }
            
            // Get last updated date
            let lastUpdatedQuery = "SELECT MAX(last_updated) FROM phrases;"
            let lastUpdatedResult = self.sqliteManager.queryData(lastUpdatedQuery, parameters: nil) { statement in
                let timestamp = sqlite3_column_double(statement, 0)
                return Date(timeIntervalSince1970: timestamp)
            }
            
            // Combine results
            let totalPhrases = totalResult?.success ?? 0
            let categoryCounts = Dictionary(uniqueKeysWithValues: categoriesResult?.success ?? [])
            let avgConfidence = avgConfidenceResult?.success ?? 0.0
            let lastUpdated = lastUpdatedResult?.success
            let isHealthy = (totalPhrases > 0)
            
            let statistics = DatabaseStatistics(
                totalPhrases: totalPhrases,
                categories: categoryCounts,
                averageConfidence: avgConfidence,
                lastUpdated: lastUpdated,
                isHealthy: isHealthy
            )
            
            completion(.success(statistics))
        }
    }
    
    /// Get translation confidence for a phrase
    func getTranslationConfidence(
        for text: String,
        direction: TranslationDirection,
        completion: @escaping (SQLiteManager.DatabaseResult<Double>) -> Void
    ) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let key = self.generateKey(forText: text, direction: direction)
            let query = "SELECT confidence FROM phrases WHERE key = ? LIMIT 1;"
            let parameters: [Any] = [key]
            
            let result = self.sqliteManager.queryData(query, parameters: parameters) { statement in
                return Double(sqlite3_column_double(statement, 0))
            }
            
            switch result {
            case .success(let confidences):
                if let confidence = confidences.first {
                    completion(.success(confidence))
                } else {
                    completion(.success(0.0))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Check if a phrase exists
    func phraseExists(
        for text: String,
        direction: TranslationDirection,
        completion: @escaping (SQLiteManager.DatabaseResult<Bool>) -> Void
    ) {
        databaseQueue.async { [weak self] in
            guard let self = self else { return }
            
            let key = self.generateKey(forText: text, direction: direction)
            let query = "SELECT COUNT(*) FROM phrases WHERE key = ?;"
            let parameters: [Any] = [key]
            
            let result = self.sqliteManager.queryData(query, parameters: parameters) { statement in
                return Int(sqlite3_column_int(statement, 0)) > 0
            }
            
            switch result {
            case .success(let exists):
                if let exists = exists.first {
                    completion(.success(exists))
                } else {
                    completion(.success(false))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get cached phrase (if available)
    func getCachedPhrase(
        for text: String,
        direction: TranslationDirection,
        completion: @escaping (Phrase?) -> Void
    ) {
        let key = generateKey(forText: text, direction: direction)
        completion(cache.object(forKey: key as NSString))
    }
    
    /// Cache a phrase for faster access
    func cachePhrase(_ phrase: Phrase, for text: String, direction: TranslationDirection) {
        let key = generateKey(forText: text, direction: direction)
        cache.setObject(phrase, forKey: key as NSString)
    }
    
    /// Clear the cache
    func clearCache() {
        cache.removeAllObjects()
    }
    
    // MARK: - Private Methods
    
    private func transformRowToPhrase(_ statement: OpaquePointer) -> Phrase? {
        guard let key = String(cString: sqlite3_column_text(statement, 1)) else { return nil }
        guard let humanText = String(cString: sqlite3_column_text(statement, 2)) else { return nil }
        guard let dogText = String(cString: sqlite3_column_text(statement, 3)) else { return nil }
        guard let categoryString = String(cString: sqlite3_column_text(statement, 4)) else { return nil }
        guard let category = PhraseCategory(rawValue: categoryString) else { return nil }
        
        let id = Int(sqlite3_column_int(statement, 0))
        let lastUpdated = Date(timeIntervalSince1970: sqlite3_column_double(statement, 5))
        let confidence = Double(sqlite3_column_double(statement, 6))
        let usageCount = Int(sqlite3_column_int(statement, 7))
        
        return Phrase(
            id: id,
            key: key,
            humanText: humanText,
            dogText: dogText,
            category: category,
            lastUpdated: lastUpdated,
            confidence: confidence,
            usageCount: usageCount
        )
    }
    
    private func generateKey(for phrase: Phrase) -> String {
        return generateKey(forText: phrase.humanText, direction: .humanToDog)
    }
    
    private func generateKey(forText text: String, direction: TranslationDirection) -> String {
        let normalizedText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let directionPrefix = direction == .humanToDog ? "htd" : "dth"
        return "\(directionPrefix)_\(normalizedText)"
    }
    
    private func getLastInsertedID() -> SQLiteManager.DatabaseResult<Int> {
        let query = "SELECT last_insert_rowid();"
        let result = sqliteManager.queryData(query, parameters: nil) { statement in
            return Int(sqlite3_column_int(statement, 0))
        }
        
        switch result {
        case .success(let ids):
            return .success(ids.first ?? 0)
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - TranslationEngine Extension

extension TranslationEngine {
    static let shared = TranslationEngine()
    var currentDirection: TranslationDirection {
        // This would be set based on the current translation direction
        return .humanToDog
    }
}