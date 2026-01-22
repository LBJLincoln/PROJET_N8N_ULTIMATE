#!/bin/bash
# ============================================
# N8N MCP ULTIMATE - Environment File Creator
# ============================================
# Interactive script to create .env file securely

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
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}N8N MCP ULTIMATE - Environment Setup${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Warning: .env file already exists!${NC}"
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted. Existing .env file preserved.${NC}"
        exit 0
    fi
fi

# Copy template
cp "$ENV_EXAMPLE" "$ENV_FILE"
echo -e "${GREEN}Created .env from template${NC}"
echo ""

# Function to update env variable
update_env() {
    local key=$1
    local value=$2
    # Escape special characters for sed
    local escaped_value=$(printf '%s\n' "$value" | sed -e 's/[\/&]/\\&/g')
    sed -i "s|^${key}=.*|${key}=${escaped_value}|" "$ENV_FILE"
}

# Prompt for credentials
echo -e "${BLUE}Enter your credentials (press Enter to skip):${NC}"
echo ""

# PostgreSQL
echo -e "${YELLOW}PostgreSQL (Neon):${NC}"
read -p "POSTGRES_URL (full connection string): " pg_url
if [ -n "$pg_url" ]; then
    update_env "POSTGRES_URL" "$pg_url"
    # Extract components if possible
    if [[ $pg_url =~ postgresql://([^:]+):([^@]+)@([^:]+):([0-9]+)/([^?]+) ]]; then
        update_env "POSTGRES_USER" "${BASH_REMATCH[1]}"
        update_env "POSTGRES_PASSWORD" "${BASH_REMATCH[2]}"
        update_env "POSTGRES_HOST" "${BASH_REMATCH[3]}"
        update_env "POSTGRES_PORT" "${BASH_REMATCH[4]}"
        update_env "POSTGRES_DB" "${BASH_REMATCH[5]}"
    fi
fi
echo ""

# Redis
echo -e "${YELLOW}Redis (Upstash):${NC}"
read -p "REDIS_URL (full connection string): " redis_url
if [ -n "$redis_url" ]; then
    update_env "REDIS_URL" "$redis_url"
    # Extract host and password if possible
    if [[ $redis_url =~ rediss://(:?)([^@]+)@([^:]+):([0-9]+) ]]; then
        update_env "REDIS_PASSWORD" "${BASH_REMATCH[2]}"
        update_env "REDIS_HOST" "${BASH_REMATCH[3]}"
        update_env "REDIS_PORT" "${BASH_REMATCH[4]}"
    fi
fi
echo ""

# N8N
echo -e "${YELLOW}N8N Cloud:${NC}"
read -p "N8N_URL (e.g., https://your-instance.app.n8n.cloud): " n8n_url
if [ -n "$n8n_url" ]; then
    update_env "N8N_URL" "$n8n_url"
    update_env "N8N_API_URL" "${n8n_url}/api/v1"
fi
echo ""

# OpenAI
echo -e "${YELLOW}OpenAI:${NC}"
read -p "OPENAI_API_KEY: " openai_key
if [ -n "$openai_key" ]; then
    update_env "OPENAI_API_KEY" "$openai_key"
fi
echo ""

# Summary
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Environment file created successfully!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "File location: ${BLUE}$ENV_FILE${NC}"
echo ""
echo -e "${YELLOW}Security reminders:${NC}"
echo "  - Never commit .env to git (it's in .gitignore)"
echo "  - Never share credentials in chat/messages"
echo "  - Rotate credentials if they were exposed"
echo ""
echo -e "Next step: Run ${GREEN}./scripts/setup_database.sh${NC} to initialize the database"
