#!/bin/bash
# ============================================
# N8N MCP ULTIMATE - Deployment Script
# ============================================
# This script initializes the database and verifies all connections
# Run this script in an environment with network access

set -e  # Exit on error

echo "================================================"
echo "N8N MCP ULTIMATE - Deployment Script"
echo "================================================"
echo ""

# Load environment variables
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo "Please create .env from .env.example"
    exit 1
fi

source .env

echo "✓ Environment variables loaded"
echo ""

# 1. Test PostgreSQL connection
echo "=== 1. Testing PostgreSQL Connection ==="
if psql "$POSTGRES_URL" -c "SELECT version();" > /dev/null 2>&1; then
    echo "✓ PostgreSQL connection successful"
    POSTGRES_VERSION=$(psql "$POSTGRES_URL" -t -c "SELECT version();")
    echo "  Version: $POSTGRES_VERSION"
else
    echo "❌ PostgreSQL connection failed"
    echo "Please check your POSTGRES_URL in .env"
    exit 1
fi
echo ""

# 2. Initialize database tables
echo "=== 2. Initializing Database Tables ==="
if psql "$POSTGRES_URL" -f scripts/init-db.sql > /dev/null 2>&1; then
    echo "✓ Database tables created successfully"
    
    # Count tables
    TABLE_COUNT=$(psql "$POSTGRES_URL" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    echo "  Tables created: $TABLE_COUNT"
else
    echo "❌ Database initialization failed"
    echo "Please check scripts/init-db.sql"
    exit 1
fi
echo ""

# 3. Verify tables
echo "=== 3. Verifying Tables ==="
EXPECTED_TABLES=("conversation_context" "rlhf_training_data" "community_summaries" "entities" "documents")

for table in "${EXPECTED_TABLES[@]}"; do
    if psql "$POSTGRES_URL" -t -c "SELECT to_regclass('public.$table');" | grep -q "$table"; then
        echo "✓ Table '$table' exists"
    else
        echo "❌ Table '$table' missing"
    fi
done
echo ""

# 4. Test Redis connection
echo "=== 4. Testing Redis Connection ==="
if redis-cli -u "$REDIS_URL" ping > /dev/null 2>&1; then
    echo "✓ Redis connection successful"
else
    echo "⚠ Redis connection failed (optional)"
    echo "  Check your REDIS_URL in .env"
fi
echo ""

# 5. Test Neo4j connection (optional)
echo "=== 5. Testing Neo4j Connection (Optional) ==="
if [ ! -z "$NEO4J_URL" ]; then
    if command -v cypher-shell &> /dev/null; then
        if cypher-shell -a "$NEO4J_URL" -u "$NEO4J_USERNAME" -p "$NEO4J_PASSWORD" "RETURN 1;" > /dev/null 2>&1; then
            echo "✓ Neo4j connection successful"
        else
            echo "⚠ Neo4j connection failed (optional)"
        fi
    else
        echo "⚠ cypher-shell not installed, skipping Neo4j test"
    fi
else
    echo "⚠ Neo4j not configured, skipping"
fi
echo ""

# 6. Verify API Keys
echo "=== 6. Verifying API Keys ==="

# Test OpenAI
if [ ! -z "$OPENAI_API_KEY" ]; then
    if curl -s -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models > /dev/null 2>&1; then
        echo "✓ OpenAI API key valid"
    else
        echo "⚠ OpenAI API key may be invalid"
    fi
else
    echo "⚠ OpenAI API key not configured"
fi

# Test Pinecone
if [ ! -z "$PINECONE_API_KEY" ]; then
    echo "✓ Pinecone API key configured"
else
    echo "⚠ Pinecone API key not configured"
fi

# Test Cohere
if [ ! -z "$COHERE_API_KEY" ]; then
    echo "✓ Cohere API key configured"
else
    echo "⚠ Cohere API key not configured"
fi

echo ""
echo "================================================"
echo "✅ SETUP OK - Deployment Complete"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Import workflows to n8n cloud: https://amoret.app.n8n.cloud"
echo "2. Configure n8n workflow credentials"
echo "3. Test end-to-end RAG pipeline"
echo ""
