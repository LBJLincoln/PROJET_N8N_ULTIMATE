# N8N MCP ULTIMATE - Setup Guide

**Generated:** 2026-01-21  
**Session:** claude/setup-n8n-mcp-skills-onKkM  
**Status:** Configuration Complete - Ready for Deployment

---

## 🎯 Overview

This setup configures a complete RAG (Retrieval-Augmented Generation) system with n8n workflows, integrated with:
- **n8n Cloud**: Workflow orchestration
- **Redis (Upstash)**: Caching and session management
- **PostgreSQL**: Structured data storage
- **MCP Skills**: Custom Claude Code skills for n8n integration

---

## 📁 Repository Structure

```
PROJET_N8N_ULTIMATE/
├── .env                    # Environment configuration (✓ CREATED)
├── config/
│   ├── postgres.sql        # Original SQL schema
│   └── env.yaml           # Original env template
├── scripts/
│   └── init-db.sql        # Database initialization (✓ CREATED)
├── workflows/              # n8n workflow definitions
│   ├── enrichment.json
│   ├── ingestion.json
│   ├── monitor.json
│   ├── orchestrator.json
│   ├── rag_classic.json
│   ├── rag_graph.json
│   └── rag_tabular.json
├── n8n-mcp/               # MCP server (cloned)
├── n8n-skills/            # MCP skills (cloned)
└── error-logs/            # Setup logs
```

---

## ✅ Completed Setup Steps

### 1. **MCP Skills Cloned**
```bash
✓ n8n-mcp repository cloned
✓ n8n-skills repository cloned
```

### 2. **Environment Configuration Created**
File: `.env`

**Configured Services:**
- ✓ N8N Cloud URL: `https://amoret.app.n8n.cloud`
- ✓ Redis Upstash: `dynamic-frog-47846.upstash.io:6379` (TLS)
- ✓ OpenAI API endpoints
- ✓ Security settings (CORS, IP whitelist)

**Pending Configuration** (Add API keys):
- `OPENAI_API_KEY=`
- `PINECONE_API_KEY=`
- `PINECONE_URL=`
- `NEO4J_URL=`, `NEO4J_USERNAME=`, `NEO4J_PASSWORD=`
- `POSTGRES_URL=`, `POSTGRES_USER=`, `POSTGRES_PASSWORD=`
- `COHERE_API_KEY=`
- `UNSTRUCTURED_API_KEY=`

### 3. **Database Initialization Script Created**
File: `scripts/init-db.sql`

**Tables to be Created:**
1. `conversation_context` - L2/L3 memory for conversations
2. `rlhf_training_data` - RLHF feedback and training data
3. `community_summaries` - Graph community detection results
4. `entities` - Extracted entities for enrichment
5. `documents` - Main documents table with versioning

**Features:**
- Proper indexes for performance
- JSONB fields for flexible data
- Versioning and quality tracking
- Multi-tenancy support

---

## 🚀 Deployment Steps

### Step 1: Configure Missing API Keys

Edit `.env` and add your API keys:

```bash
# Required API Keys
OPENAI_API_KEY=sk-...
PINECONE_API_KEY=...
PINECONE_URL=https://xxx.pinecone.io
PINECONE_INDEX_NAME=n8n-rag
COHERE_API_KEY=...
```

### Step 2: Setup PostgreSQL Database

**Option A: Local PostgreSQL**
```bash
# Start PostgreSQL
sudo systemctl start postgresql

# Create database
createdb n8n_rag

# Run initialization script
psql -d n8n_rag -f scripts/init-db.sql

# Update .env with connection details
POSTGRES_URL=postgresql://user:pass@localhost:5432/n8n_rag
```

**Option B: Cloud PostgreSQL (Recommended)**
```bash
# Use Supabase, Neon, or other cloud provider
# Get connection string and update .env
POSTGRES_URL=postgresql://user:pass@host:5432/dbname
```

### Step 3: Verify Redis Connection

```bash
# Test Redis Upstash connection
redis-cli -u rediss://:AbrmAAIncDFlYjliNTA0MzRhNmQ0YjlkYjIzZGM1Y2I2NGJlNDRmMnAxNDc4NDY@dynamic-frog-47846.upstash.io:6379 ping
# Expected: PONG
```

### Step 4: Setup Neo4j (Optional for Graph RAG)

If using graph RAG workflows:
```bash
# Sign up for Neo4j Aura (free tier available)
# Update .env with credentials
NEO4J_URL=neo4j+s://xxx.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=...
```

### Step 5: Deploy n8n Workflows

```bash
# Access n8n cloud
open https://amoret.app.n8n.cloud

# Import workflows from workflows/ directory:
# 1. orchestrator.json (main orchestration)
# 2. ingestion.json (document ingestion)
# 3. enrichment.json (entity enrichment)
# 4. rag_classic.json (classic RAG)
# 5. rag_graph.json (graph RAG)
# 6. rag_tabular.json (tabular data RAG)
# 7. monitor.json (system monitoring)

# Configure credentials in n8n:
# - PostgreSQL connection
# - Redis connection
# - OpenAI API key
# - Other service credentials
```

### Step 6: Configure MCP Skills

```bash
# Copy MCP configuration example
cp n8n-skills/.mcp.json.example ~/.mcp.json

# Build skills
cd n8n-skills
./build.sh

# Skills will be available in Claude Code
```

### Step 7: Verify Setup

Run verification script:
```bash
# Check database tables
psql $POSTGRES_URL -c "\dt"

# Check Redis
redis-cli -u $REDIS_URL ping

# Test n8n API
curl -X GET https://amoret.app.n8n.cloud/api/v1/workflows \
  -H "X-N8N-API-KEY: YOUR_API_KEY"
```

---

## 🔧 Environment Variables Reference

### Required (Already Configured)
- `N8N_URL` - n8n cloud instance
- `REDIS_URL` - Redis Upstash with credentials
- `REDIS_TLS=true` - Enable TLS for Redis

### Required (Needs API Keys)
- `OPENAI_API_KEY` - OpenAI API access
- `POSTGRES_URL` - PostgreSQL connection
- `PINECONE_API_KEY` - Pinecone vector DB
- `COHERE_API_KEY` - Cohere reranking

### Optional (Advanced Features)
- `NEO4J_URL` - Neo4j graph database
- `UNSTRUCTURED_API_KEY` - Document parsing
- `SENTRY_DSN` - Error tracking
- `SLACK_WEBHOOK_URL` - Notifications

---

## 📊 Database Schema Summary

### conversation_context
- Stores conversation state and entities
- Multi-tenant support
- JSONB for flexible entity storage

### rlhf_training_data
- Captures user feedback (implicit/explicit)
- Tracks good/bad examples
- Stores reasoning paths for analysis

### community_summaries
- Results from graph community detection
- Links entities via communities
- Relevance scoring

### entities
- Named entities extracted from documents
- Confidence scores
- Type classification

### documents
- Main document storage
- Versioning and obsolescence tracking
- Quality scoring
- Parent-child relationships for chunks

---

## 🔍 Troubleshooting

### Redis Connection Issues
```bash
# Test connection
redis-cli -u $REDIS_URL ping

# Check TLS
openssl s_client -connect dynamic-frog-47846.upstash.io:6379
```

### PostgreSQL Issues
```bash
# Check connection
psql $POSTGRES_URL -c "SELECT version();"

# Verify tables
psql $POSTGRES_URL -c "\dt"
```

### n8n Workflow Issues
- Check n8n logs in cloud dashboard
- Verify credentials are configured
- Test connections in workflow editor

---

## 📝 Next Steps

1. ✓ Configuration files created
2. ⏳ Add API keys to .env
3. ⏳ Setup PostgreSQL and run init-db.sql
4. ⏳ Test Redis connection
5. ⏳ Import workflows to n8n cloud
6. ⏳ Configure workflow credentials
7. ⏳ Test end-to-end RAG pipeline

---

## 🔐 Security Notes

- ⚠️ Never commit `.env` file to git (already in .gitignore)
- ⚠️ Rotate Redis password if exposed
- ⚠️ Use environment-specific API keys
- ⚠️ Enable IP whitelisting in production
- ⚠️ Configure CORS for allowed origins only

---

## 📚 Documentation

- **n8n Skills**: See `n8n-skills/README.md` and `n8n-skills/CLAUDE.md`
- **MCP Server**: See `n8n-mcp/README.md`
- **Original Config**: See `config/postgres.sql` and `config/env.yaml`

---

## 🆘 Support

If you encounter issues:
1. Check error-logs/agent1-error.txt for setup errors
2. Review n8n workflow execution logs
3. Verify all environment variables are set
4. Test individual components (Redis, Postgres, n8n API)

---

**Setup prepared by:** Claude Code (RALPH AI LOOP)  
**Network Status:** Sandbox environment (no external connectivity during setup)  
**Configuration Status:** Ready for deployment with network access
