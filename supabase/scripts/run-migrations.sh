#!/bin/sh
# Apply Supabase migrations to local database
# Usage: ./run-migrations.sh [migration_number]

set -e

DB_HOST="${PGHOST:-localhost}"
DB_PORT="${PGPORT:-5432}"
DB_NAME="${PGDATABASE:-postgres}"
DB_USER="${PGUSER:-postgres}"
DB_PASSWORD="${PGPASSWORD:-postgres}"

export PGPASSWORD="$DB_PASSWORD"

# Determine which migrations to run
MIGRATION_START=1
MIGRATION_END=16

if [ -n "$1" ]; then
    MIGRATION_START=$1
    MIGRATION_END=$1
fi

MIGRATIONS_DIR="$(cd "$(dirname "$0")/.." && pwd)/migrations"

echo "Applying migrations $MIGRATION_START to $MIGRATION_END..."

for i in $(seq $MIGRATION_START $MIGRATION_END); do
    MIGRATION_FILE="$(printf '%04d' $i)_*.sql"
    FULL_PATH=$(ls "$MIGRATIONS_DIR"/${MIGRATION_FILE} 2>/dev/null | head -1)

    if [ -f "$FULL_PATH" ]; then
        echo "Running migration $i: $(basename $FULL_PATH)..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$FULL_PATH"
        echo "Migration $i completed."
    else
        echo "Warning: Migration $i not found, skipping."
    fi
done

echo "All migrations applied successfully."
