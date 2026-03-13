// MARK: - SQLiteManager

import Foundation
import SQLite3

/// Core SQLite connection and operations manager
final class SQLiteManager {
    
    // MARK: - Public Types
    
    /// Database operation result
    enum DatabaseResult<T> {
        case success(T)
        case failure(Error)
    }
    
    /// Database error types
    enum DatabaseError: Error, LocalizedError {
        case databaseNotFound
        case connectionFailed
        case queryFailed
        case schemaCreationFailed
        case fileAccessError
        case databaseCorrupted
        case migrationFailed
        
        var errorDescription: String? {
            switch self {
            case .databaseNotFound:
                return "Database file not found"
            case .connectionFailed:
                return "Failed to connect to database"
            case .queryFailed:
                return "Database query failed"
            case .schemaCreationFailed:
                return "Failed to create database schema"
            case .fileAccessError:
                return "File access error"
            case .databaseCorrupted:
                return "Database file is corrupted"
            case .migrationFailed:
                return "Database migration failed"
            }
        }
    }
    
    // MARK: - Private Properties
    
    static let shared = SQLiteManager()
    private let databaseFileName = "wooftalk_offline.sqlite"
    private var database: OpaquePointer? = nil
    private let databaseQueue = DispatchQueue(label: "com.wooftalk.offline.database")
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    private init() {
        initializeDatabase()
    }
    
    deinit {
        closeDatabase()
    }
    
    // MARK: - Public Methods
    
    /// Initialize database connection and schema
    func initializeDatabase() {
        databaseQueue.async { [weak self] in
            self?.openDatabase()
            self?.createSchema()
        }
    }
    
    /// Close database connection
    func closeDatabase() {
        databaseQueue.sync {
            if self.database != nil {
                sqlite3_close(self.database)
                self.database = nil
            }
        }
    }
    
    /// Execute a query with parameters
    func executeQuery(_ query: String, parameters: [Any]? = nil) -> DatabaseResult<Void> {
        var result: DatabaseResult<Void> = .failure(DatabaseError.queryFailed)
        
        databaseQueue.sync {
            guard let db = self.database else {
                result = .failure(DatabaseError.connectionFailed)
                return
            }
            
            var statement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                if let params = parameters {
                    for (index, param) in params.enumerated() {
                        let paramIndex = Int32(index + 1)
                        switch param {
                        case let value as String:
                            sqlite3_bind_text(statement, paramIndex, value, -1, nil)
                        case let value as Int:
                            sqlite3_bind_int(statement, paramIndex, Int32(value))
                        case let value as Double:
                            sqlite3_bind_double(statement, paramIndex, value)
                        default:
                            sqlite3_bind_null(statement, paramIndex)
                        }
                    }
                }
                
                if sqlite3_step(statement) == SQLITE_DONE {
                    result = .success(()
                } else {
                    result = .failure(DatabaseError.queryFailed)
                }
            } else {
                result = .failure(DatabaseError.queryFailed)
            }
            
            sqlite3_finalize(statement)
        }
        
        return result
    }
    
    /// Query for data with parameters
    func queryData<T>(_ query: String, parameters: [Any]? = nil, transform: (OpaquePointer) -> T?) -> DatabaseResult<[T]> {
        var result: DatabaseResult<[T]> = .failure(DatabaseError.queryFailed)
        
        databaseQueue.sync {
            guard let db = self.database else {
                result = .failure(DatabaseError.connectionFailed)
                return
            }
            
            var statement: OpaquePointer? = nil
            var results: [T] = []
            
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                if let params = parameters {
                    for (index, param) in params.enumerated() {
                        let paramIndex = Int32(index + 1)
                        switch param {
                        case let value as String:
                            sqlite3_bind_text(statement, paramIndex, value, -1, nil)
                        case let value as Int:
                            sqlite3_bind_int(statement, paramIndex, Int32(value))
                        case let value as Double:
                            sqlite3_bind_double(statement, paramIndex, value)
                        default:
                            sqlite3_bind_null(statement, paramIndex)
                        }
                    }
                }
                
                while sqlite3_step(statement) == SQLITE_ROW {
                    if let transformed = transform(statement) {
                        results.append(transformed)
                    }
                }
                
                result = .success(results)
            } else {
                result = .failure(DatabaseError.queryFailed)
            }
            
            sqlite3_finalize(statement)
        }
        
        return result
    }
    
    /// Get database statistics
    func getDatabaseStatistics() -> DatabaseResult<DatabaseStatistics> {
        var statistics = DatabaseStatistics(
            fileSize: 0,
            tableCount: 0,
            phraseCount: 0,
            lastModified: nil,
            isHealthy: false
        )
        
        databaseQueue.sync {
            guard let db = self.database else {
                return
            }
            
            // Get file size
            if let fileURL = getDatabaseFileURL() {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let fileSize = attributes[FileAttributeKey.size] as? NSNumber {
                        statistics.fileSize = fileSize.intValue
                    }
                    if let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date {
                        statistics.lastModified = modificationDate
                    }
                } catch {
                    // Ignore file access errors
                }
            }
            
            // Get table count and phrase count
            let tableQuery = "SELECT name FROM sqlite_master WHERE type='table';"
            let countQuery = "SELECT COUNT(*) FROM phrases;"
            
            var tableStatement: OpaquePointer? = nil
            var countStatement: OpaquePointer? = nil
            
            if sqlite3_prepare_v2(db, tableQuery, -1, &tableStatement, nil) == SQLITE_OK {
                var tableCount = 0
                while sqlite3_step(tableStatement) == SQLITE_ROW {
                    tableCount += 1
                }
                statistics.tableCount = tableCount
                sqlite3_finalize(tableStatement)
            }
            
            if sqlite3_prepare_v2(db, countQuery, -1, &countStatement, nil) == SQLITE_OK {
                if sqlite3_step(countStatement) == SQLITE_ROW {
                    statistics.phraseCount = Int(sqlite3_column_int(countStatement, 0))
                }
                sqlite3_finalize(countStatement)
            }
            
            statistics.isHealthy = (statistics.tableCount > 0)
        }
        
        return .success(statistics)
    }
    
    // MARK: - Private Methods
    
    private func openDatabase() {
        guard let fileURL = getDatabaseFileURL() else {
            return
        }
        
        if sqlite3_open(fileURL.path, &database) != SQLITE_OK {
            print("Error opening offline database")
            database = nil
        }
    }
    
    private func createSchema() {
        let createTableQuery = ""
            + "CREATE TABLE IF NOT EXISTS phrases ("
            + "id INTEGER PRIMARY KEY AUTOINCREMENT,"
            + "key TEXT NOT NULL UNIQUE,"
            + "human_text TEXT NOT NULL,"
            + "dog_text TEXT NOT NULL,"
            + "category TEXT,"
            + "last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,"
            + "confidence REAL DEFAULT 0.8,"
            + "usage_count INTEGER DEFAULT 1"
            + ");"
        
        let createIndexQuery = "CREATE INDEX IF NOT EXISTS idx_key ON phrases (key);"
        let createCategoryIndexQuery = "CREATE INDEX IF NOT EXISTS idx_category ON phrases (category);"
        let createUpdatedIndexQuery = "CREATE INDEX IF NOT EXISTS idx_last_updated ON phrases (last_updated);"
        
        executeQuery(createTableQuery)
        executeQuery(createIndexQuery)
        executeQuery(createCategoryIndexQuery)
        executeQuery(createUpdatedIndexQuery)
    }
    
    private func getDatabaseFileURL() -> URL? {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first?.appendingPathComponent(databaseFileName)
    }
}

// MARK: - DatabaseStatistics

struct DatabaseStatistics: CustomStringConvertible {
    let fileSize: Int
    let tableCount: Int
    let phraseCount: Int
    let lastModified: Date?
    let isHealthy: Bool
    
    var description: String {
        return "DatabaseStatistics(fileSize: \(fileSize) bytes, tables: \(tableCount), phrases: \(phraseCount), lastModified: \(String(describing: lastModified)), healthy: \(isHealthy))"
    }
}