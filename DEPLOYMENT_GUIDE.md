# N8N RAG System - Complete Deployment Guide

Complete guide for deploying the n8n RAG system from scratch to production.

**Version:** Production Ready
**Last Updated:** 2026-01-21
**Status:** ✅ All Components Ready

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Configuration](#environment-configuration)
3. [Database Setup](#database-setup)
4. [Workflow Import](#workflow-import)
5. [Post-Import Configuration](#post-import-configuration)
6. [Testing & Validation](#testing--validation)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Accounts & Services

Before starting, ensure you have:

- ✅ **n8n Cloud Account** (or self-hosted n8n instance)
  - URL: https://amoret.app.n8n.cloud
  - API Key: Available in Settings → API

- ✅ **PostgreSQL Database** (Supabase, Neon, or self-hosted)
  - Version: 12+
  - Required extensions: `pg_trgm` (optional for full-text search)

- ✅ **Redis Instance** (Upstash recommended)
  - TLS support required
  - Currently configured: `dynamic-frog-47846.upstash.io:6379`

- ✅ **OpenAI API Access**
  - Models: GPT-4-turbo, GPT-4o-mini, GPT-4o
  - Embeddings: text-embedding-3-large

- ✅ **Pinecone Vector Database**
  - Index name: `n8n-rag`
  - Dimension: 3072 (for text-embedding-3-large)

- ✅ **Cohere API** (for reranking)
  - Model: rerank-multilingual-v3.0

- ⚠️ **Neo4j Database** (optional, for Graph RAG only)
  - Neo4j Aura or self-hosted
  - Version: 4.4+

### Required Tools

```bash
# PostgreSQL client
psql --version  # 12+

# Redis client (for testing)
redis-cli --version  # 6+

# curl (for API testing)
curl --version

# bash (for running scripts)
bash --version  # 4+
```

---

## Environment Configuration

### Step 1: Copy Environment Template

```bash
cp .env.example .env
```

### Step 2: Configure n8n

Edit `.env` and add:

```bash
# n8n Cloud Configuration
N8N_URL=https://amoret.app.n8n.cloud
N8N_API_URL=https://amoret.app.n8n.cloud/api/v1
N8N_API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  # Your API key
```

**Getting your n8n API Key:**
1. Log in to https://amoret.app.n8n.cloud
2. Go to Settings → API
3. Click "Create API Key"
4. Copy the key (starts with `eyJ...`)

### Step 3: Configure PostgreSQL

```bash
# PostgreSQL Configuration
POSTGRES_URL=postgresql://user:password@host:5432/dbname
POSTGRES_HOST=your-postgres-host.supabase.co
POSTGRES_PORT=5432
POSTGRES_DB=n8n_rag
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your-secure-password
```

**For Supabase:**
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Settings → Database
4. Copy the "Connection string" (select "psql" format)

### Step 4: Configure Redis

```bash
# Redis Configuration (Upstash)
REDIS_URL=rediss://:PASSWORD@dynamic-frog-47846.upstash.io:6379
REDIS_HOST=dynamic-frog-47846.upstash.io
REDIS_PORT=6379
REDIS_PASSWORD=AbrmAAIncDFlYjliNTA0MzRhNmQ0YjlkYjIzZGM1Y2I2NGJlNDRmMnAxNDc4NDY
REDIS_TLS=true
```

**For Upstash:**
1. Go to https://upstash.com
2. Create a Redis database
3. Copy the "Redis URL" (TLS format starting with `rediss://`)

### Step 5: Configure API Keys

```bash
# OpenAI
OPENAI_API_KEY=sk-proj-...  # Your OpenAI API key

# Pinecone
PINECONE_API_KEY=pcsk_...
PINECONE_URL=https://your-index-xxx.pinecone.io
PINECONE_INDEX_NAME=n8n-rag

# Cohere
COHERE_API_KEY=...
COHERE_API_URL=https://api.cohere.ai/v1/rerank

# Neo4j (Optional - for Graph RAG)
NEO4J_URL=neo4j+s://xxx.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=...
```

### Step 6: Configure LLM Models

```bash
# LLM Configuration
LLM_API_URL=https://api.openai.com/v1/chat/completions
DEFAULT_LLM_MODEL=gpt-4-turbo
ROUTER_MODEL=gpt-4o-mini
HYDE_MODEL=gpt-4o
SQL_MODEL=gpt-4o
RERANKER_MODEL=rerank-multilingual-v3.0

# Embedding Configuration
EMBEDDING_API_URL=https://api.openai.com/v1/embeddings
EMBEDDING_MODEL=text-embedding-3-large
```

### Step 7: Security Settings

```bash
# Security
ALLOWED_ORIGINS=https://amoret.app.n8n.cloud,https://app.company.com
IP_WHITELIST=10.0.0.0/8,192.168.0.0/16

# Application
NODE_ENV=production
LOG_LEVEL=info
TENANT_ID=default
```

### Verify Configuration

```bash
# Check .env file exists and has correct permissions
ls -la .env
# Should show: -rw------- (600) for security

# Verify required variables are set
grep -E "N8N_API_KEY|OPENAI_API_KEY|POSTGRES_URL|PINECONE_API_KEY" .env
```

---

## Database Setup

### Step 1: Test PostgreSQL Connection

```bash
# Load environment variables
source .env

# Test connection
psql "$POSTGRES_URL" -c "SELECT version();"
```

**Expected output:**
```
                                                 version
----------------------------------------------------------------------------------------------------------
 PostgreSQL 15.1 on x86_64-pc-linux-gnu...
(1 row)
```

### Step 2: Initialize Database Tables

```bash
# Run init script (creates 5 tables)
psql "$POSTGRES_URL" -f scripts/init-db.sql
```

**Expected output:**
```
CREATE TABLE
CREATE INDEX
COMMENT ON TABLE
...
(Repeats for 5 tables)
```

### Step 3: Verify Tables

```bash
# List all tables
psql "$POSTGRES_URL" -c "\dt"

# Expected tables:
# - conversation_context
# - rlhf_training_data
# - community_summaries
# - entities
# - documents
```

### Database Schema Details

**Table 1: conversation_context**
- Purpose: L2/L3 conversational memory
- Stores: conversation_id, tenant_id, entities_json (JSONB), last_intent
- Index: `idx_conv_ctx_lookup` on (conversation_id, tenant_id)

**Table 2: rlhf_training_data**
- Purpose: RLHF feedback and training data collection
- Stores: query, response, feedback_score, reasoning_path (JSONB), good/bad flags
- Index: `idx_rlhf_quality` on quality flags

**Table 3: community_summaries**
- Purpose: Graph community detection results
- Stores: entity_names (TEXT[]), summary, relevance_score, algorithm
- Index: GIN index on entity_names array

**Table 4: entities**
- Purpose: Named entity storage for enrichment
- Stores: name, type, tenant_id, confidence score
- Indexes: lookup index, type index

**Table 5: documents**
- Purpose: Main document storage with versioning
- Stores: content, metadata (JSONB), versioning, quality_score, parent-child relationships
- Indexes: obsolete index, parent index, tenant index

---

## Workflow Import

You have **3 options** for importing workflows into n8n.

### Option 1: Automated Import via Script (Recommended)

**Step 1: Set API Key**
```bash
export N8N_API_KEY="your-api-key-here"
# Or use the one from .env
source .env
export N8N_API_KEY="$N8N_API_KEY"
```

**Step 2: Run Import Script**
```bash
# Import all 9 workflows
chmod +x scripts/import_to_n8n.sh
./scripts/import_to_n8n.sh --all
```

**Step 3: Verify Output**
```
============================================================
n8n Workflow Import Script
============================================================
Instance: https://amoret.app.n8n.cloud

📝 Importing orchestrator... ✓ Success (ID: abc123)
📝 Importing ingestion... ✓ Success (ID: def456)
📝 Importing rag_classic... ✓ Success (ID: ghi789)
...
============================================================
Import completed: 9/9 workflows imported
============================================================
```

**Import Specific Workflows:**
```bash
# Import only test workflows
./scripts/import_to_n8n.sh orchestrator_TestCopy.json ingestion_TestCopy.json

# Import only production workflows
./scripts/import_to_n8n.sh orchestrator.json ingestion.json enrichment.json
```

### Option 2: Quick Import Script (Alternative)

If the above doesn't work, try the quick import script:

```bash
export N8N_API_KEY="your-api-key"
./IMPORT_RAPIDE.sh
```

This script:
- Downloads workflows from GitHub (backup method)
- Imports all 9 workflows
- Handles errors automatically

### Option 3: Manual Import via n8n UI

**Step 1: Access n8n**
```
https://amoret.app.n8n.cloud
```

**Step 2: For Each Workflow**
1. Click "+" (new workflow)
2. Select "Import from File"
3. Choose the JSON file (e.g., `workflows/orchestrator.json`)
4. Click "Import"
5. Save the workflow

**Step 3: Import Order (Recommended)**
1. `orchestrator_TestCopy.json` (test first)
2. `ingestion_TestCopy.json` (test first)
3. `orchestrator.json`
4. `ingestion.json`
5. `enrichment.json`
6. `rag_classic.json`
7. `rag_graph.json`
8. `rag_tabular.json`
9. `monitor.json`

---

## Post-Import Configuration

After importing workflows, you need to configure credentials in n8n.

### Required Credentials

Go to n8n → Settings → Credentials and create the following:

#### 1. PostgreSQL Connection

**Name:** `Postgres Production`
**Type:** PostgreSQL
**Configuration:**
```
Host: your-postgres-host.supabase.co
Port: 5432
Database: n8n_rag
User: postgres
Password: your-password
SSL: Enabled
```

**Test:** Click "Test credentials"

**Used by:**
- orchestrator.json (L2 memory)
- monitor.json (RLHF data)
- enrichment.json (entity storage)

#### 2. OpenAI API

**Name:** `OpenAI API Key`
**Type:** HTTP Header Auth
**Configuration:**
```
Header Name: Authorization
Header Value: Bearer sk-proj-YOUR-API-KEY
```

**Used by:**
- All RAG workflows (LLM calls)
- ingestion.json (embeddings)
- enrichment.json (entity extraction)

#### 3. Pinecone

**Name:** `Pinecone API`
**Type:** HTTP Header Auth
**Configuration:**
```
Header Name: Api-Key
Header Value: pcsk_YOUR-PINECONE-API-KEY
```

**Used by:**
- rag_classic.json
- ingestion.json (vector storage)

#### 4. Redis (Upstash)

**Name:** `Redis Upstash`
**Type:** Redis
**Configuration:**
```
Host: dynamic-frog-47846.upstash.io
Port: 6379
Password: your-redis-password
SSL/TLS: Enabled
```

**Used by:**
- orchestrator.json (caching)
- All RAG workflows (session management)

#### 5. Neo4j (Optional - for Graph RAG)

**Name:** `Neo4j Production`
**Type:** Neo4j
**Configuration:**
```
URL: neo4j+s://xxx.databases.neo4j.io
Username: neo4j
Password: your-neo4j-password
```

**Used by:**
- rag_graph.json
- enrichment.json (entity relationships)

#### 6. Cohere (for Reranking)

**Name:** `Cohere API`
**Type:** HTTP Header Auth
**Configuration:**
```
Header Name: Authorization
Header Value: Bearer YOUR-COHERE-API-KEY
```

**Used by:**
- rag_classic.json (reranking)
- rag_graph.json (reranking)

#### 7. Slack Webhook (Optional - for Monitoring)

**Name:** `Slack Monitoring`
**Type:** Webhook
**Configuration:**
```
URL: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

**Used by:**
- monitor.json (notifications)

### Verify Credentials

For each credential:
1. Click "Test credentials" button
2. Verify success message
3. If error, check connection details and API keys

---

## Testing & Validation

### Phase 1: Test with TestCopy Workflows

**Step 1: Open TestCopy Workflow**
```
n8n → Workflows → "Orchestrator V6.0 - Master Router [PRODUCTION] HARDENED _TestCopy"
```

**Step 2: Use Chat Trigger**
1. Find the "Chat Trigger" node (first node)
2. Click on it
3. Click "Chat" button
4. Type a test query: `"What is machine learning?"`
5. Press Enter

**Step 3: Observe Execution**
- All nodes should execute successfully
- Green checkmarks on each node
- Response should appear in chat

**Expected Behavior:**
- Init & Validation → Fetch L2 Memory → Merge Context → LLM Router → Route to RAG → Response

**Step 4: Test Ingestion**
```
n8n → Workflows → "Document Ingestion Pipeline V5.0 - FULL PIPELINE _TestCopy"
```

Same process: Use Chat Trigger with sample document text.

### Phase 2: Test Production Webhooks

**Step 1: Activate Workflow**
```
n8n → Workflows → "Orchestrator V6.0 - Master Router [PRODUCTION] HARDENED"
Toggle: Inactive → Active
```

**Step 2: Get Webhook URL**
```
Node: "Webhook Entry Point"
URL: https://amoret.app.n8n.cloud/webhook/rag-v5-orchestrator
```

**Step 3: Test with curl**
```bash
curl -X POST "https://amoret.app.n8n.cloud/webhook/rag-v5-orchestrator" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is machine learning?",
    "user_id": "test_user_001",
    "tenant_id": "default",
    "conversation_id": "conv_test_001"
  }'
```

**Expected Response:**
```json
{
  "status": "success",
  "response": "Machine learning is...",
  "reasoning": "QUALITATIVE",
  "conversation_id": "conv_test_001",
  "execution_time_ms": 1234
}
```

### Phase 3: End-to-End RAG Pipeline

**Test Classic RAG:**
```bash
curl -X POST "https://amoret.app.n8n.cloud/webhook/rag-v5-orchestrator" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Explain neural networks",
    "user_id": "test",
    "tenant_id": "default"
  }'
```

**Test Graph RAG:**
```bash
curl -X POST "https://amoret.app.n8n.cloud/webhook/rag-v5-orchestrator" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the relationships between transformers and attention mechanisms?",
    "user_id": "test",
    "tenant_id": "default"
  }'
```

**Test Tabular RAG:**
```bash
curl -X POST "https://amoret.app.n8n.cloud/webhook/rag-v5-orchestrator" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is the average revenue in Q3?",
    "user_id": "test",
    "tenant_id": "default"
  }'
```

### Validation Checklist

- [ ] All 9 workflows imported successfully
- [ ] All credentials configured and tested
- [ ] TestCopy workflows work with Chat Trigger
- [ ] Production webhooks respond correctly
- [ ] PostgreSQL tables have data after queries
- [ ] Redis cache is populated
- [ ] Pinecone vectors are stored
- [ ] Monitoring workflow logs to Slack (if configured)
- [ ] RLHF feedback is collected in database

---

## Troubleshooting

### Common Issues

#### 1. "Unauthorized" or HTTP 401

**Problem:** Invalid n8n API key

**Solution:**
```bash
# Regenerate API key in n8n Settings → API
export N8N_API_KEY="new-api-key"
./scripts/import_to_n8n.sh --all
```

#### 2. "CONNECT tunnel failed, response 403"

**Problem:** Network/firewall blocking API access

**Solution:** Use manual import via n8n UI (Option 3)

#### 3. "Missing credentials" in workflow

**Problem:** Credentials not configured in n8n

**Solution:**
1. Go to n8n → Settings → Credentials
2. Create required credentials (see Post-Import Configuration)
3. Re-save the workflow

#### 4. PostgreSQL connection failed

**Problem:** Invalid connection string or firewall

**Solution:**
```bash
# Test connection manually
psql "postgresql://user:pass@host:5432/db" -c "SELECT 1;"

# Check firewall allows your IP
# For Supabase: Add your IP in Database Settings → Connection Pooling
```

#### 5. Redis connection failed

**Problem:** TLS not enabled or wrong password

**Solution:**
```bash
# Test Redis connection
redis-cli -u "rediss://:password@host:6379" ping

# Should return: PONG
```

#### 6. Workflow execution fails with "OpenAI API error"

**Problem:** Invalid API key or quota exceeded

**Solution:**
```bash
# Test OpenAI API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Check quota: https://platform.openai.com/account/usage
```

#### 7. Pinecone "Index not found"

**Problem:** Index doesn't exist or wrong name

**Solution:**
1. Go to https://app.pinecone.io
2. Create index named `n8n-rag`
3. Dimension: 3072 (for text-embedding-3-large)
4. Metric: cosine

#### 8. Neo4j connection timeout

**Problem:** Database paused (Neo4j Aura) or wrong credentials

**Solution:**
```bash
# Check Neo4j status in Aura Console
# Resume database if paused
# Verify credentials in .env
```

### Debugging Tools

**Check n8n Workflow Execution Logs:**
1. n8n → Executions
2. Click on failed execution
3. Review error messages in each node

**Check PostgreSQL Tables:**
```bash
# List all tables
psql "$POSTGRES_URL" -c "\dt"

# Check conversation context
psql "$POSTGRES_URL" -c "SELECT * FROM conversation_context LIMIT 5;"

# Check RLHF data
psql "$POSTGRES_URL" -c "SELECT * FROM rlhf_training_data LIMIT 5;"
```

**Check Redis Cache:**
```bash
redis-cli -u "$REDIS_URL" KEYS "*"
redis-cli -u "$REDIS_URL" GET "conversation:test"
```

**Monitor Logs:**
```bash
# Watch n8n logs (if self-hosted)
docker logs -f n8n

# Watch PostgreSQL logs (if self-hosted)
tail -f /var/log/postgresql/postgresql.log
```

---

## Deployment Checklist

Before going to production, verify:

### Pre-Production

- [ ] All environment variables configured in `.env`
- [ ] `.env` file excluded from git (in `.gitignore`)
- [ ] PostgreSQL database created and tables initialized
- [ ] Redis instance accessible with TLS
- [ ] All API keys valid and have sufficient quota
- [ ] Pinecone index created with correct dimensions
- [ ] Neo4j database ready (if using Graph RAG)

### Import

- [ ] All 9 workflows imported to n8n
- [ ] All credentials configured in n8n
- [ ] Credentials tested successfully
- [ ] Workflows saved and error-free

### Testing

- [ ] TestCopy workflows tested with Chat Trigger
- [ ] Production webhooks tested with curl
- [ ] End-to-end RAG pipeline validated
- [ ] Database tables populated with test data
- [ ] Monitoring workflow sending notifications

### Security

- [ ] API keys rotated if exposed
- [ ] CORS configured with allowed origins
- [ ] IP whitelist configured (if needed)
- [ ] TLS/SSL enabled for all connections
- [ ] Credentials use environment variables (not hardcoded)

### Monitoring

- [ ] Slack webhook configured for alerts
- [ ] RLHF feedback collection enabled
- [ ] Database backups configured
- [ ] Error logging and tracking enabled

---

## Production Deployment Script

For automated deployment, use the provided script:

```bash
# Full deployment (DB + verification)
./scripts/deploy.sh
```

This script will:
1. ✅ Load environment variables from `.env`
2. ✅ Test PostgreSQL connection
3. ✅ Initialize database tables
4. ✅ Verify all 5 tables created
5. ✅ Test Redis connection
6. ✅ Test Neo4j connection (optional)
7. ✅ Verify API keys
8. ✅ Output "SETUP OK" or error details

---

## Support & Resources

**Documentation:**
- [README.md](./README.md) - Quick start guide
- [WORKFLOWS_REFERENCE.md](./WORKFLOWS_REFERENCE.md) - Workflow technical docs

**n8n Resources:**
- n8n Documentation: https://docs.n8n.io/
- n8n API Reference: https://docs.n8n.io/api/
- n8n Community: https://community.n8n.io/

**Service Documentation:**
- PostgreSQL: https://www.postgresql.org/docs/
- Redis: https://redis.io/docs/
- Pinecone: https://docs.pinecone.io/
- Neo4j: https://neo4j.com/docs/
- OpenAI: https://platform.openai.com/docs/

---

**Deployment Guide Version:** 1.0
**Last Updated:** 2026-01-21
**Status:** ✅ Production Ready
