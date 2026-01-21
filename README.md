# N8N RAG System - Production Ready

A complete Retrieval-Augmented Generation (RAG) system built with n8n workflows, featuring multiple RAG strategies (Classic, Graph, Tabular), entity enrichment, and RLHF feedback monitoring.

## 🎯 Overview

This project provides a production-ready RAG system with:
- **7 Production Workflows**: Orchestrator, Ingestion, Enrichment, 3 RAG variants, Monitoring
- **2 Test Workflows**: TestCopy versions with Chat Triggers for easy testing
- **Multi-Strategy RAG**: Classic (vector), Graph (Neo4j), Tabular (SQL)
- **Complete Infrastructure**: PostgreSQL, Redis, Pinecone, Neo4j, OpenAI integration
- **RLHF Monitoring**: Feedback collection and training data generation

## 🚀 Quick Start (3 Steps)

### 1. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env and add your credentials:
# - N8N_API_KEY (from n8n Settings → API)
# - OPENAI_API_KEY
# - PINECONE_API_KEY
# - POSTGRES_URL
# - NEO4J credentials (optional)
```

### 2. Initialize Database

```bash
# Run deployment script (creates all 5 PostgreSQL tables)
./scripts/deploy.sh
```

### 3. Import Workflows to n8n

**Option A - Automated Import:**
```bash
export N8N_API_KEY="your-api-key-here"
./scripts/import_to_n8n.sh --all
```

**Option B - Manual Import:**
1. Open https://amoret.app.n8n.cloud (or your n8n instance)
2. Go to Workflows → Import from File
3. Import each JSON file from `workflows/` directory
4. Configure credentials in n8n

## 📊 System Architecture

```
┌─────────────────────────────────────────┐
│         n8n Cloud Workflows              │
│    (Master Orchestrator Router)          │
└──────────────┬──────────────────────────┘
               │
      ┌────────┼────────┐
      ▼        ▼        ▼
┌─────────┐ ┌──────┐ ┌─────────┐
│  Classic│ │Graph │ │ Tabular │
│   RAG   │ │ RAG  │ │   RAG   │
└─────────┘ └──────┘ └─────────┘
      │        │        │
      ▼        ▼        ▼
┌──────────────────────────────────┐
│       Data Layer                  │
│  PostgreSQL │ Redis │ Pinecone   │
│  Neo4j      │ OpenAI│ Cohere     │
└──────────────────────────────────┘
```

## 📁 Project Structure

```
PROJET_N8N_ULTIMATE/
├── README.md                    # This file
├── DEPLOYMENT_GUIDE.md          # Complete deployment instructions
├── WORKFLOWS_REFERENCE.md       # Workflows technical documentation
│
├── workflows/                   # n8n workflow definitions (9 files)
│   ├── orchestrator.json        # Master Router V6.0
│   ├── ingestion.json           # Document ingestion pipeline
│   ├── enrichment.json          # Entity enrichment
│   ├── rag_classic.json         # Classic vector RAG
│   ├── rag_graph.json           # Graph-based RAG (Neo4j)
│   ├── rag_tabular.json         # SQL/Tabular RAG
│   ├── monitor.json             # Feedback & RLHF monitoring
│   ├── orchestrator_TestCopy.json   # Test version (Chat Trigger)
│   └── ingestion_TestCopy.json      # Test version (Chat Trigger)
│
├── scripts/
│   ├── deploy.sh                # Full deployment (DB init + verification)
│   ├── import_to_n8n.sh         # Import workflows via n8n API
│   └── init-db.sql              # PostgreSQL schema (5 tables)
│
├── config/
│   ├── postgres.sql             # Original SQL schema reference
│   └── env.yaml                 # Original environment variables reference
│
└── .env.example                 # Environment configuration template
```

## 🗄️ Database Schema

**5 PostgreSQL Tables:**

| Table | Purpose |
|-------|---------|
| `conversation_context` | L2/L3 memory, stores conversation state and extracted entities |
| `rlhf_training_data` | RLHF feedback collection with reasoning paths |
| `community_summaries` | Graph community detection results from Neo4j |
| `entities` | Named entities extracted from documents (NER) |
| `documents` | Main document storage with versioning and quality tracking |

## 🔧 Configuration

### Required Services

| Service | Purpose | Configuration |
|---------|---------|---------------|
| **n8n Cloud** | Workflow orchestration | `https://amoret.app.n8n.cloud` |
| **PostgreSQL** | Structured data storage | Supabase, Neon, or self-hosted |
| **Redis** | Caching & sessions | Upstash with TLS |
| **Pinecone** | Vector embeddings | Index: `n8n-rag` |
| **OpenAI** | LLM & embeddings | GPT-4, text-embedding-3-large |
| **Cohere** | Reranking | `rerank-multilingual-v3.0` |
| **Neo4j** | Graph database (optional) | For Graph RAG workflow |

### API Keys Required

```bash
# Required
OPENAI_API_KEY=sk-...
PINECONE_API_KEY=pcsk_...
N8N_API_KEY=eyJ...
POSTGRES_URL=postgresql://...
COHERE_API_KEY=...

# Optional (for Graph RAG)
NEO4J_URL=neo4j+s://...
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=...
```

## 🧪 Testing

### Test with TestCopy Workflows (Recommended)

1. Import `orchestrator_TestCopy.json` and `ingestion_TestCopy.json`
2. Open workflow in n8n
3. Use **Chat Trigger** to send test queries
4. Example query: `"What is machine learning?"`

### Test Production Webhooks

```bash
curl -X POST "https://amoret.app.n8n.cloud/webhook/rag-v5-orchestrator" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is machine learning?",
    "user_id": "test_user",
    "tenant_id": "default"
  }'
```

## 📚 Workflows Overview

### Production Workflows

| Workflow | Lines | Description |
|----------|-------|-------------|
| **orchestrator.json** | 353 | Master Router V6.0 - Routes queries to appropriate RAG strategy |
| **ingestion.json** | 506 | Document ingestion pipeline with chunking and embedding |
| **enrichment.json** | 572 | Entity extraction and enrichment pipeline |
| **rag_classic.json** | 346 | Classic RAG with vector similarity (Pinecone) |
| **rag_graph.json** | 419 | Graph RAG using Neo4j for entity relationships |
| **rag_tabular.json** | 416 | SQL-based RAG for quantitative/tabular queries |
| **monitor.json** | 424 | Feedback collection and RLHF training data generation |

### Test Workflows

- **orchestrator_TestCopy.json** - Same as orchestrator but with Chat Trigger instead of webhook
- **ingestion_TestCopy.json** - Same as ingestion but with Chat Trigger instead of webhook

**Difference:** TestCopy workflows use `@n8n/n8n-nodes-langchain.chatTrigger` for easy testing without webhook setup.

## 🔐 Security

- ✅ All credentials in `.env` (excluded from git)
- ✅ TLS enabled for Redis
- ✅ SSL enabled for PostgreSQL and Neo4j
- ✅ CORS configured with allowed origins
- ✅ IP whitelist support
- ✅ API key authentication for all services

## 📖 Documentation

- **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Complete deployment instructions, troubleshooting, and post-import configuration
- **[WORKFLOWS_REFERENCE.md](./WORKFLOWS_REFERENCE.md)** - Detailed technical documentation of all 9 workflows

## 🆘 Troubleshooting

See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for:
- Common deployment issues
- Connection testing
- Credential configuration
- Workflow debugging

## 🎯 Next Steps

After importing workflows:

1. **Configure n8n Credentials** (Settings → Credentials):
   - PostgreSQL connection
   - OpenAI API key
   - Pinecone credentials
   - Redis connection
   - Neo4j credentials (for Graph RAG)

2. **Test with TestCopy workflows** using Chat Trigger

3. **Activate production workflows** and test with webhooks

4. **Configure monitoring** (Slack notifications in monitor.json)

5. **Ingest sample documents** and test end-to-end RAG pipeline

## 📊 System Status

- ✅ **Workflows**: 9/9 ready for import
- ✅ **Database Schema**: 5 tables defined
- ✅ **Scripts**: Deployment and import scripts ready
- ✅ **Documentation**: Complete guides and references
- ✅ **Configuration**: All templates and examples provided

## 🔗 Resources

- **n8n Instance**: https://amoret.app.n8n.cloud
- **n8n Documentation**: https://docs.n8n.io/
- **n8n API Docs**: https://docs.n8n.io/api/

---

**Built with:** n8n, PostgreSQL, Redis, Pinecone, Neo4j, OpenAI, Cohere
**Version:** Production Ready
**Last Updated:** 2026-01-21
