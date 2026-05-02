#!/bin/bash
# Local Supabase setup script for Phase 51 UAT testing
# This script starts a local Supabase instance using Docker

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=================================="
echo "  WoofTalk Phase 51 Local Setup"
echo "=================================="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop first."
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is available"
echo ""

# Check for existing Supabase containers
if docker ps -a | grep -q supabase_db; then
    echo "⚠️  Existing Supabase containers found."
    echo "   Stopping and removing them..."
    docker-compose -f docker-compose.yml down -v 2>/dev/null || true
    sleep 2
fi

# Start Docker services
echo "📦 Starting Supabase Docker containers..."
echo "   - PostgreSQL database"
echo "   - Kong API gateway"
echo "   - Inbucket email testing"
echo ""
docker-compose -f docker-compose.yml up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check DB health
echo "🔍 Checking database health..."
MAX_RETRIES=30
RETRY=0
until docker exec supabase_db pg_isready -U postgres &>/dev/null || [ $RETRY -eq $MAX_RETRIES ]; do
    RETRY=$((RETRY+1))
    echo "  Waiting for database... ($RETRY/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "❌ Database failed to start after $MAX_RETRIES attempts"
    exit 1
fi

echo "✅ Database is ready"
echo ""

# Run migrations
echo "🔄 Applying database migrations..."
sleep 5
./scripts/run-migrations.sh

echo ""
echo "=================================="
echo "  Local Supabase Setup Complete!"
echo "=================================="
echo ""
echo "Connection Details:"
echo "  Host:     localhost"
echo "  Port:     5432"
echo "  Database: postgres"
echo "  User:     postgres"
echo "  Password: postgres"
echo ""
echo "Services:"
echo "  Database:      localhost:5432"
echo "  API Gateway:   localhost:8000"
echo "  Kong Admin:    localhost:8001"
echo "  Mailbox (email): http://localhost:9000"
echo ""
echo "Environment Variables for Web App:"
echo "  NEXT_PUBLIC_SUPABASE_URL=http://localhost:5432"
echo "  NEXT_PUBLIC_SUPABASE_ANON_KEY=ANON_KEY"
echo "  SUPABASE_SERVICE_ROLE_KEY=postgres"
echo ""
echo "Next Steps:"
echo "  1. Configure .env.local in web/ with the above values"
echo "  2. Run: npm run dev"
echo "  3. Create test users at http://localhost:3000"
echo "  4. Run UAT tests from web app"
echo ""
