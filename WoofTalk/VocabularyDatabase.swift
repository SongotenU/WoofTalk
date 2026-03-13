// MARK: - VocabularyDatabase

import Foundation
import SQLite3
import AVFoundation

/// SQLite database for storing translation vocabulary
final class VocabularyDatabase {
    
    // MARK: - Public Types
    
    /// Vocabulary lookup result
    struct VocabularyLookupResult {
        let translatedText: String
        let confidence: Double
        let source: Source
        
        enum Source {
            case mlModel
            case database
            case simpleMapping
        }
    }
    
    /// Vocabulary coverage statistics
    struct VocabularyCoverage: CustomStringConvertible {
        let humanToDogPhrases: Int
        let dogToHumanPhrases: Int
        let totalPhrases: Int
        let coveragePercentage: Double
        
        var description: String {
            return "VocabularyCoverage(humanToDog: \(humanToDogPhrases), dogToHuman: \(dogToHumanPhrases), total: \(totalPhrases), coverage: \(String(format: "%.1f", coveragePercentage))%)")
        }
    }
    
    // MARK: - Private Properties
    
    static let shared = VocabularyDatabase()
    private let databaseFileName = "wooftalk_vocabulary.sqlite"
    private var database: OpaquePointer? = nil
    private let databaseQueue = DispatchQueue(label: "com.wooftalk.vocabulary.database")
    
    // MARK: - Initialization
    
    private init() {
        openDatabase()
        createTables()
        populateDatabase()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Public Methods
    
    /// Lookup human speech to dog translation
    func lookupHumanToDog(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        
        let normalizedText = normalizeText(text)
        var result = ""
        
        databaseQueue.sync {
            result = lookupHumanToDogInternal(normalizedText)
        }
        
        return result
    }
    
    /// Lookup dog vocalization to human translation
    func lookupDogToHuman(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        
        let normalizedText = normalizeText(text)
        var result = ""
        
        databaseQueue.sync {
            result = lookupDogToHumanInternal(normalizedText)
        }
        
        return result
    }
    
    /// Get vocabulary coverage statistics
    func getCoverageStatistics() -> VocabularyCoverage {
        var coverage = VocabularyCoverage(
            humanToDogPhrases: 0,
            dogToHumanPhrases: 0,
            totalPhrases: 0,
            coveragePercentage: 0.0
        )
        
        databaseQueue.sync {
            coverage = getCoverageStatisticsInternal()
        }
        
        return coverage
    }
    
    /// Get translation confidence for a phrase
    func getTranslationConfidence(_ text: String, direction: TranslationDirection) -> Double {
        guard !text.isEmpty else { return 0.0 }
        
        let normalizedText = normalizeText(text)
        var confidence = 0.0
        
        databaseQueue.sync {
            confidence = getTranslationConfidenceInternal(normalizedText, direction: direction)
        }
        
        return confidence
    }
    
    // MARK: - Private Methods
    
    private func openDatabase() {
        let fileURL = getDatabaseFileURL()
        
        if sqlite3_open(fileURL.path, &database) != SQLITE_OK {
            print("Error opening vocabulary database")
            database = nil
        }
    }
    
    private func closeDatabase() {
        if database != nil {
            sqlite3_close(database)
            database = nil
        }
    }
    
    private func createTables() {
        let createTableQuery = ""
            + "CREATE TABLE IF NOT EXISTS vocabulary ("
            + "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            + "human_text TEXT NOT NULL,"
            + "dog_text TEXT NOT NULL,"
            + "context TEXT,"
            + "frequency INTEGER DEFAULT 1,"
            + "confidence REAL DEFAULT 0.8,"
            + "category TEXT,"
            + "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
            + "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
            + ");"
        
        let createIndexQuery = "CREATE INDEX IF NOT EXISTS idx_human_text ON vocabulary (human_text);"
        let createDogIndexQuery = "CREATE INDEX IF NOT EXISTS idx_dog_text ON vocabulary (dog_text);"
        
        executeQuery(createTableQuery)
        executeQuery(createIndexQuery)
        executeQuery(createDogIndexQuery)
    }
    
    private func populateDatabase() {
        // Check if database is empty
        let countQuery = "SELECT COUNT(*) FROM vocabulary;"
        var statement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(database, countQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let count = sqlite3_column_int(statement, 0)
                sqlite3_finalize(statement)
                
                // If database is empty, populate with initial vocabulary
                if count == 0 {
                    populateInitialVocabulary()
                }
            }
        }
    }
    
    private func populateInitialVocabulary() {
        let initialVocabulary: [[String]] = [
            // Basic commands
            ["sit", "woof woof woof"],
            ["stay", "woof woof woof woof"],
            ["come", "woof woof woof woof woof"],
            ["no", "woof woof woof woof woof woof woof woof"],
            ["yes", "woof woof woof woof woof woof woof woof woof"],
            ["good boy", "woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof woof