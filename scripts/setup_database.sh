#!/bin/bash
# ============================================
# N8N MCP ULTIMATE - Database Setup Script
# ============================================
# This script sets up the PostgreSQL database and verifies connections

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}N8N MCP ULTIMATE - Database Setup${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if .env exists
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${YELLOW}No .env file found!${NC}"
    echo ""
    echo -e "Please create your .env file:"
    echo -e "  ${GREEN}cp $PROJECT_ROOT/.env.example $PROJECT_ROOT/.env${NC}"
    echo ""
    echo -e "Then edit it with your credentials:"
    echo -e "  ${GREEN}nano $PROJECT_ROOT/.env${NC}"
    echo ""
    echo -e "${YELLOW}Required variables for database setup:${NC}"
    echo "  - POSTGRES_URL (full connection string)"
    echo "  - REDIS_URL (full connection string with password)"
    echo ""
    exit 1
fi

# Load environment variables
echo -e "${BLUE}Loading environment variables...${NC}"
set -a
source "$PROJECT_ROOT/.env"
set +a

# Validate required variables
MISSING_VARS=""

if [ -z "$POSTGRES_URL" ]; then
    MISSING_VARS="$MISSING_VARS POSTGRES_URL"
fi

if [ -n "$MISSING_VARS" ]; then
    echo -e "${RED}Missing required environment variables:${NC}"
    echo -e "${YELLOW}$MISSING_VARS${NC}"
    echo ""
    echo "Please update your .env file with these variables."
    exit 1
fi

# Function to test PostgreSQL connection
test_postgres() {
    echo -e "${BLUE}Testing PostgreSQL connection...${NC}"

    if command -v psql &> /dev/null; then
        if psql "$POSTGRES_URL" -c "SELECT 1;" &> /dev/null; then
            echo -e "${GREEN}PostgreSQL connection successful!${NC}"
            return 0
        else
            echo -e "${RED}PostgreSQL connection failed!${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}psql not installed. Testing with Python...${NC}"
        python3 -c "
import sys
try:
    import psycopg2
    conn = psycopg2.connect('$POSTGRES_URL')
    conn.close()
    print('PostgreSQL connection successful!')
    sys.exit(0)
except ImportError:
    print('Neither psql nor psycopg2 available. Skipping PostgreSQL test.')
    sys.exit(0)
except Exception as e:
    print(f'PostgreSQL connection failed: {e}')
    sys.exit(1)
"
    fi
}

# Function to test Redis connection
test_redis() {
    echo -e "${BLUE}Testing Redis connection...${NC}"

    if [ -z "$REDIS_URL" ]; then
        echo -e "${YELLOW}REDIS_URL not set. Skipping Redis test.${NC}"
        return 0
    fi

    if command -v redis-cli &> /dev/null; then
        if redis-cli -u "$REDIS_URL" PING 2>/dev/null | grep -q "PONG"; then
            echo -e "${GREEN}Redis connection successful!${NC}"
            return 0
        else
            echo -e "${RED}Redis connection failed!${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}redis-cli not installed. Testing with Python...${NC}"
        python3 -c "
import sys
try:
    import redis
    r = redis.from_url('$REDIS_URL')
    r.ping()
    print('Redis connection successful!')
    sys.exit(0)
except ImportError:
    print('Neither redis-cli nor redis-py available. Skipping Redis test.')
    sys.exit(0)
except Exception as e:
    print(f'Redis connection failed: {e}')
    sys.exit(1)
"
    fi
}

# Function to initialize database
init_database() {
    echo -e "${BLUE}Initializing database schema...${NC}"

    SQL_FILE="$SCRIPT_DIR/init-db.sql"

    if [ ! -f "$SQL_FILE" ]; then
        echo -e "${RED}SQL file not found: $SQL_FILE${NC}"
        return 1
    fi

    if command -v psql &> /dev/null; then
        psql "$POSTGRES_URL" -f "$SQL_FILE"
        echo -e "${GREEN}Database schema initialized successfully!${NC}"
    else
        echo -e "${YELLOW}psql not available. Please run init-db.sql manually.${NC}"
        echo ""
        echo "You can run it via:"
        echo "  1. Neon Console SQL Editor"
        echo "  2. Any PostgreSQL client"
        echo ""
        echo "SQL file location: $SQL_FILE"
        return 0
    fi
}

# Main execution
echo ""
echo -e "${BLUE}Step 1: Testing connections${NC}"
echo "----------------------------------------"

test_postgres
PG_STATUS=$?

test_redis
REDIS_STATUS=$?

echo ""

if [ $PG_STATUS -eq 0 ]; then
    echo -e "${BLUE}Step 2: Initialize database schema${NC}"
    echo "----------------------------------------"

    read -p "Do you want to initialize the database schema? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        init_database
    else
        echo -e "${YELLOW}Skipping database initialization.${NC}"
    fi
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Setup Summary${NC}"
echo -e "${BLUE}============================================${NC}"
echo -e "PostgreSQL: $([ $PG_STATUS -eq 0 ] && echo -e "${GREEN}Connected${NC}" || echo -e "${RED}Failed${NC}")"
echo -e "Redis:      $([ $REDIS_STATUS -eq 0 ] && echo -e "${GREEN}Connected${NC}" || echo -e "${YELLOW}Skipped/Failed${NC}")"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
