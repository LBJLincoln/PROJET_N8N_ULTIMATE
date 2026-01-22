#!/bin/bash
# ============================================
# N8N MCP ULTIMATE - Database Setup Script
# ============================================
# Generated: 2026-01-22
# Session: claude/setup-db-env-config-lLxYQ
# Description: Sets up PostgreSQL tables and verifies connections
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ERROR_LOG="$PROJECT_DIR/error-logs/agent1-error.txt"
SQL_FILE="$SCRIPT_DIR/init-db.sql"

# Database credentials (Supabase PostgreSQL)
PG_HOST="db.ayqviqmxifzmhphiqfmj.supabase.co"
PG_PORT="5432"
PG_DATABASE="postgres"
PG_USER="postgres"
PG_PASSWORD="LxtBJKljhhBassDS"

# Redis credentials (Upstash)
REDIS_URL="https://dynamic-frog-47846.upstash.io"
REDIS_TOKEN="AbrmAAIncDFlYjliNTA0MzRhNmQ0YjlkYjIzZGM1Y2I2NGJlNDRmMnAxNDc4NDY"

# ============================================
# Helper Functions
# ============================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"
}

init_error_log() {
    mkdir -p "$(dirname "$ERROR_LOG")"
    echo "# ============================================" > "$ERROR_LOG"
    echo "# Agent 1 - Setup Error Log" >> "$ERROR_LOG"
    echo "# Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$ERROR_LOG"
    echo "# ============================================" >> "$ERROR_LOG"
    echo "" >> "$ERROR_LOG"
}

# ============================================
# PostgreSQL Functions
# ============================================

check_psql() {
    if ! command -v psql &> /dev/null; then
        log_error "psql command not found. Please install PostgreSQL client."
        log_error "Ubuntu/Debian: sudo apt-get install postgresql-client"
        log_error "macOS: brew install postgresql"
        return 1
    fi
    return 0
}

test_postgres_connection() {
    log_info "Testing PostgreSQL connection to $PG_HOST..."

    if PGPASSWORD="$PG_PASSWORD" psql \
        -h "$PG_HOST" \
        -p "$PG_PORT" \
        -U "$PG_USER" \
        -d "$PG_DATABASE" \
        -c "SELECT 1 as test;" > /dev/null 2>&1; then
        log_info "PostgreSQL connection successful!"
        return 0
    else
        log_error "Failed to connect to PostgreSQL at $PG_HOST:$PG_PORT"
        return 1
    fi
}

create_postgres_tables() {
    log_info "Creating PostgreSQL tables from $SQL_FILE..."

    if [ ! -f "$SQL_FILE" ]; then
        log_error "SQL file not found: $SQL_FILE"
        return 1
    fi

    # Execute SQL file
    if PGPASSWORD="$PG_PASSWORD" psql \
        -h "$PG_HOST" \
        -p "$PG_PORT" \
        -U "$PG_USER" \
        -d "$PG_DATABASE" \
        -f "$SQL_FILE" 2>&1; then
        log_info "PostgreSQL tables created successfully!"
        return 0
    else
        log_error "Failed to create PostgreSQL tables"
        return 1
    fi
}

verify_postgres_tables() {
    log_info "Verifying PostgreSQL tables..."

    TABLES=$(PGPASSWORD="$PG_PASSWORD" psql \
        -h "$PG_HOST" \
        -p "$PG_PORT" \
        -U "$PG_USER" \
        -d "$PG_DATABASE" \
        -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('conversation_context', 'rlhf_training_data', 'community_summaries', 'entities', 'documents');" 2>/dev/null | tr -d ' ')

    EXPECTED_TABLES=("conversation_context" "rlhf_training_data" "community_summaries" "entities" "documents")

    for table in "${EXPECTED_TABLES[@]}"; do
        if echo "$TABLES" | grep -q "$table"; then
            log_info "  - Table '$table' exists"
        else
            log_warn "  - Table '$table' not found"
        fi
    done
}

# ============================================
# Redis Functions
# ============================================

test_redis_connection() {
    log_info "Testing Redis (Upstash) connection..."

    if ! command -v curl &> /dev/null; then
        log_error "curl command not found"
        return 1
    fi

    # Test with PING command via Upstash REST API
    RESPONSE=$(curl -s -X POST "$REDIS_URL" \
        -H "Authorization: Bearer $REDIS_TOKEN" \
        -H "Content-Type: application/json" \
        -d '["PING"]' 2>&1)

    if echo "$RESPONSE" | grep -q "PONG"; then
        log_info "Redis (Upstash) connection successful!"
        return 0
    else
        log_error "Failed to connect to Redis at $REDIS_URL"
        log_error "Response: $RESPONSE"
        return 1
    fi
}

# ============================================
# Main Setup
# ============================================

main() {
    echo ""
    echo "============================================"
    echo " N8N MCP ULTIMATE - Database Setup"
    echo "============================================"
    echo ""

    init_error_log

    SETUP_OK=true

    # Step 1: Check prerequisites
    log_info "Checking prerequisites..."
    if ! check_psql; then
        SETUP_OK=false
    fi

    # Step 2: Test PostgreSQL connection
    if [ "$SETUP_OK" = true ]; then
        if ! test_postgres_connection; then
            SETUP_OK=false
        fi
    fi

    # Step 3: Create PostgreSQL tables
    if [ "$SETUP_OK" = true ]; then
        if ! create_postgres_tables; then
            SETUP_OK=false
        fi
    fi

    # Step 4: Verify tables
    if [ "$SETUP_OK" = true ]; then
        verify_postgres_tables
    fi

    # Step 5: Test Redis connection
    if [ "$SETUP_OK" = true ]; then
        if ! test_redis_connection; then
            SETUP_OK=false
        fi
    fi

    echo ""
    echo "============================================"

    if [ "$SETUP_OK" = true ]; then
        echo -e "${GREEN}Setup OK${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Setup completed successfully" >> "$ERROR_LOG"
        exit 0
    else
        echo -e "${RED}Setup FAILED - Check $ERROR_LOG${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
