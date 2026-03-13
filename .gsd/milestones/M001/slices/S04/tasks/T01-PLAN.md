---
estimated_steps: 6
estimated_files: 3
---

# T01: SQLite Database Setup

**Slice:** S04 — Offline Mode
**Milestone:** M001

## Description

Establish the SQLite database foundation for offline translation storage. This task creates the database schema, implements basic CRUD operations, and sets up the connection management needed for offline functionality.

## Steps

1. Research SQLite3 Node.js bindings and iOS integration patterns
2. Create `sqlite_manager.ts` with connection initialization and error handling
3. Define SQLite schema for phrases table (id, key, human_text, dog_text, category, last_updated)
4. Implement basic CRUD operations in `sqlite_manager.ts`
5. Create `offline_database.ts` as a higher-level abstraction for phrase operations
6. Add database initialization and migration logic

## Must-Haves

- SQLite database connection is stable and handles errors gracefully
- Phrases table schema supports all required fields for translation storage
- Basic CRUD operations (create, read, update, delete) work correctly
- Database initialization creates tables if they don't exist
- Connection is properly closed on application shutdown

## Verification

- Database file is created in the correct location
- Schema creation succeeds without errors
- Basic insert/select operations work with test data
- Connection handles concurrent access without crashes
- Error handling works for common failure scenarios

## Observability Impact

- Signals added: Database connection status, query execution times, error rates
- How a future agent inspects this: `sqlite3` CLI tool, debug logs for database operations
- Failure state exposed: Connection errors, query failures, schema issues

## Inputs

- Decision D008: SQLite for caching (from research)
- Existing translation data structure from S02
- iOS file system access patterns from S01

## Expected Output

- `offline_storage/sqlite_manager.ts` — Core SQLite connection and operations
- `offline_storage/offline_database.ts` — High-level phrase storage abstraction
- SQLite database file created and ready for use
- Basic test suite for database operations