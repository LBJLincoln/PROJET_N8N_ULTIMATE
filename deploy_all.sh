#!/bin/bash
# ============================================
# N8N RAG System - Complete Deployment Script
# ============================================
# This script performs full system deployment:
# 1. Environment validation
# 2. Database initialization
# 3. Connection testing
# 4. Workflow import to n8n
# 5. Verification and reporting
#
# Usage: ./deploy_all.sh [--skip-workflows]

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
SKIP_WORKFLOWS=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --skip-workflows)
      SKIP_WORKFLOWS=true
      shift
      ;;
  esac
done

echo "========================================================"
echo "N8N RAG System - Complete Deployment Script"
echo "========================================================"
echo ""
echo "This script will:"
echo "  1. Validate environment configuration"
echo "  2. Initialize PostgreSQL database (5 tables)"
echo "  3. Test all service connections"
echo "  4. Import workflows to n8n (9 workflows)"
echo "  5. Verify deployment status"
echo ""

# ============================================
# PHASE 1: Environment Validation
# ============================================
echo -e "${BLUE}=== Phase 1: Environment Validation ===${NC}"
echo ""

# Check .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}✗ Error: .env file not found${NC}"
    echo ""
    echo "Please create .env from .env.example:"
    echo "  cp .env.example .env"
    echo "  # Edit .env and add your credentials"
    exit 1
fi

# Load environment variables
source .env
echo -e "${GREEN}✓${NC} Environment file loaded"

# Validate required variables
required_vars=("POSTGRES_URL" "OPENAI_API_KEY" "N8N_API_KEY")
missing_vars=()

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    missing_vars+=("$var")
  fi
done

if [ ${#missing_vars[@]} -gt 0 ]; then
  echo -e "${RED}✗ Error: Missing required environment variables:${NC}"
  for var in "${missing_vars[@]}"; do
    echo "  - $var"
  done
  echo ""
  echo "Please configure these in .env file"
  exit 1
fi

echo -e "${GREEN}✓${NC} All required environment variables set"
echo ""

# ============================================
# PHASE 2: Database Initialization
# ============================================
echo -e "${BLUE}=== Phase 2: Database Initialization ===${NC}"
echo ""

# Test PostgreSQL connection
echo -n "Testing PostgreSQL connection... "
if psql "$POSTGRES_URL" -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected${NC}"
    PG_VERSION=$(psql "$POSTGRES_URL" -t -c "SELECT version();" | head -1 | xargs)
    echo "  Version: $PG_VERSION"
else
    echo -e "${RED}✗ Failed${NC}"
    echo ""
    echo "PostgreSQL connection failed. Please check:"
    echo "  - POSTGRES_URL in .env is correct"
    echo "  - Database is accessible from this network"
    echo "  - Firewall allows connection"
    exit 1
fi

# Run database initialization script
echo ""
echo "Initializing database tables..."
if psql "$POSTGRES_URL" -f scripts/init-db.sql > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Database tables created successfully"
else
    echo -e "${YELLOW}⚠${NC}  Database initialization completed with warnings (tables may already exist)"
fi

# Verify tables
echo ""
echo "Verifying tables..."
EXPECTED_TABLES=("conversation_context" "rlhf_training_data" "community_summaries" "entities" "documents")
TABLES_OK=true

for table in "${EXPECTED_TABLES[@]}"; do
    if psql "$POSTGRES_URL" -t -c "SELECT to_regclass('public.$table');" 2>/dev/null | grep -q "$table"; then
        echo -e "  ${GREEN}✓${NC} Table '$table' exists"
    else
        echo -e "  ${RED}✗${NC} Table '$table' missing"
        TABLES_OK=false
    fi
done

if [ "$TABLES_OK" = false ]; then
    echo ""
    echo -e "${RED}✗ Error: Some tables are missing${NC}"
    echo "Please check scripts/init-db.sql and database permissions"
    exit 1
fi

echo ""

# ============================================
# PHASE 3: Service Connection Testing
# ============================================
echo -e "${BLUE}=== Phase 3: Service Connection Testing ===${NC}"
echo ""

# Test Redis
echo -n "Testing Redis connection... "
if [ ! -z "$REDIS_URL" ]; then
    if command -v redis-cli &> /dev/null; then
        if redis-cli -u "$REDIS_URL" ping > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Connected${NC}"
        else
            echo -e "${YELLOW}⚠ Connection failed (optional service)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ redis-cli not installed, skipping test${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Not configured${NC}"
fi

# Test Neo4j
echo -n "Testing Neo4j connection... "
if [ ! -z "$NEO4J_URL" ]; then
    if command -v cypher-shell &> /dev/null; then
        if cypher-shell -a "$NEO4J_URL" -u "$NEO4J_USERNAME" -p "$NEO4J_PASSWORD" "RETURN 1;" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Connected${NC}"
        else
            echo -e "${YELLOW}⚠ Connection failed (optional for Graph RAG)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ cypher-shell not installed, skipping test${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Not configured (optional for Graph RAG)${NC}"
fi

# Test OpenAI API
echo -n "Testing OpenAI API... "
if curl -s -f -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Valid${NC}"
else
    echo -e "${RED}✗ Invalid or quota exceeded${NC}"
    echo ""
    echo "OpenAI API key validation failed. Please check:"
    echo "  - OPENAI_API_KEY in .env is correct"
    echo "  - API key has remaining quota"
    echo "  - Account is active"
    exit 1
fi

# Verify other API keys are set
echo -n "Checking Pinecone API key... "
if [ ! -z "$PINECONE_API_KEY" ]; then
    echo -e "${GREEN}✓ Configured${NC}"
else
    echo -e "${YELLOW}⚠ Not configured (required for Classic RAG)${NC}"
fi

echo -n "Checking Cohere API key... "
if [ ! -z "$COHERE_API_KEY" ]; then
    echo -e "${GREEN}✓ Configured${NC}"
else
    echo -e "${YELLOW}⚠ Not configured (optional for reranking)${NC}"
fi

echo ""

# ============================================
# PHASE 4: Workflow Import
# ============================================
if [ "$SKIP_WORKFLOWS" = false ]; then
    echo -e "${BLUE}=== Phase 4: Workflow Import ===${NC}"
    echo ""

    # Check if import script exists
    if [ ! -f "scripts/import_to_n8n.sh" ]; then
        echo -e "${RED}✗ Error: scripts/import_to_n8n.sh not found${NC}"
        exit 1
    fi

    # Make import script executable
    chmod +x scripts/import_to_n8n.sh

    # Run import script
    echo "Importing workflows to n8n..."
    echo "Instance: $N8N_URL"
    echo ""

    if ./scripts/import_to_n8n.sh --all; then
        echo ""
        echo -e "${GREEN}✓ All workflows imported successfully${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠ Workflow import completed with some errors${NC}"
        echo ""
        echo "You can:"
        echo "  1. Check n8n instance at $N8N_URL"
        echo "  2. Import workflows manually via n8n UI"
        echo "  3. Re-run: ./scripts/import_to_n8n.sh --all"
        echo ""
        echo "Continuing with deployment verification..."
    fi
else
    echo -e "${BLUE}=== Phase 4: Workflow Import ===${NC}"
    echo -e "${YELLOW}⚠ Skipped (--skip-workflows flag)${NC}"
    echo ""
fi

# ============================================
# PHASE 5: Deployment Verification
# ============================================
echo ""
echo -e "${BLUE}=== Phase 5: Deployment Verification ===${NC}"
echo ""

# Count database records
echo "Database status:"
CONV_COUNT=$(psql "$POSTGRES_URL" -t -c "SELECT COUNT(*) FROM conversation_context;" 2>/dev/null | xargs)
RLHF_COUNT=$(psql "$POSTGRES_URL" -t -c "SELECT COUNT(*) FROM rlhf_training_data;" 2>/dev/null | xargs)
COMM_COUNT=$(psql "$POSTGRES_URL" -t -c "SELECT COUNT(*) FROM community_summaries;" 2>/dev/null | xargs)
ENT_COUNT=$(psql "$POSTGRES_URL" -t -c "SELECT COUNT(*) FROM entities;" 2>/dev/null | xargs)
DOC_COUNT=$(psql "$POSTGRES_URL" -t -c "SELECT COUNT(*) FROM documents;" 2>/dev/null | xargs)

echo "  - conversation_context: $CONV_COUNT rows"
echo "  - rlhf_training_data: $RLHF_COUNT rows"
echo "  - community_summaries: $COMM_COUNT rows"
echo "  - entities: $ENT_COUNT rows"
echo "  - documents: $DOC_COUNT rows"

echo ""

# ============================================
# Final Summary
# ============================================
echo "========================================================"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE${NC}"
echo "========================================================"
echo ""
echo "Deployment Summary:"
echo "  ✓ Environment configured"
echo "  ✓ PostgreSQL database initialized (5 tables)"
echo "  ✓ Service connections verified"
if [ "$SKIP_WORKFLOWS" = false ]; then
    echo "  ✓ Workflows imported to n8n"
else
    echo "  ⚠ Workflows not imported (skipped)"
fi
echo ""
echo "Next Steps:"
echo ""
echo "1. Access your n8n instance:"
echo "   $N8N_URL"
echo ""
echo "2. Configure n8n credentials (if not already done):"
echo "   Settings → Credentials"
echo "   Required:"
echo "     - Postgres Production"
echo "     - OpenAI API Key"
echo "     - Pinecone API"
echo "     - Redis Upstash"
echo "   Optional:"
echo "     - Neo4j Production (for Graph RAG)"
echo "     - Cohere API (for reranking)"
echo ""
echo "3. Test workflows:"
echo "   a) Test with TestCopy workflows (Chat Trigger):"
echo "      - orchestrator_TestCopy.json"
echo "      - ingestion_TestCopy.json"
echo ""
echo "   b) Test production webhooks:"
echo "      curl -X POST \"$N8N_URL/webhook/rag-v5-orchestrator\" \\"
echo "        -H \"Content-Type: application/json\" \\"
echo "        -d '{\"query\":\"What is machine learning?\",\"user_id\":\"test\"}'"
echo ""
echo "4. Monitor execution:"
echo "   n8n → Executions"
echo ""
echo "5. Ingest documents:"
echo "   Use the ingestion workflow to add your documents"
echo ""
echo "Documentation:"
echo "  - README.md - Quick start guide"
echo "  - DEPLOYMENT_GUIDE.md - Complete deployment instructions"
echo "  - WORKFLOWS_REFERENCE.md - Technical workflow documentation"
echo ""
echo "========================================================"
echo -e "${GREEN}Deployment script completed successfully!${NC}"
echo "========================================================"
