# N8N RAG System - Complete Workflows Reference

Complete technical documentation for all 9 workflows, including architecture, nodes, credentials, variables, and data flow.

**Version:** Production Ready
**Last Updated:** 2026-01-21

---

## Table of Contents

1. [Overview](#overview)
2. [Credentials Configuration](#credentials-configuration)
3. [Environment Variables](#environment-variables)
4. [Database Tables](#database-tables)
5. [RAG Classic Workflow](#1-rag-classic-workflow)
6. [RAG Graph Workflow](#2-rag-graph-workflow)
7. [RAG Tabular Workflow](#3-rag-tabular-workflow)
8. [Ingestion Workflow](#4-ingestion-workflow)
9. [Enrichment Workflow](#5-enrichment-workflow)
10. [Monitor Workflow](#6-monitor-workflow)
11. [Orchestrator Workflow](#7-orchestrator-workflow-master-router)
12. [TestCopy Workflows](#8-testcopy-workflows)
13. [Dataset Download Workflow](#9-dataset-download-workflow)
14. [Workflow Dependencies](#workflow-dependencies)

---

## Overview

### Architecture Flow

```
User Query
    ↓
[Orchestrator] ← Master Router V6.0
    ↓
    ├─→ [RAG Classic] ← Vector similarity search (Pinecone)
    ├─→ [RAG Graph] ← Entity relationships (Neo4j)
    └─→ [RAG Tabular] ← SQL queries (PostgreSQL)
         ↓
    [Response Aggregator]
         ↓
    [Monitor] ← RLHF Feedback Collection
```

### Workflow Files

| Workflow | File | Lines | Purpose |
|----------|------|-------|---------|
| **RAG Classic** | rag_classic.json | 346 | Vector-based retrieval with Pinecone |
| **RAG Graph** | rag_graph.json | 419 | Graph-based retrieval with Neo4j |
| **RAG Tabular** | rag_tabular.json | 416 | SQL-based retrieval for quantitative queries |
| **Ingestion** | ingestion.json | 506 | Document processing and embedding |
| **Enrichment** | enrichment.json | 572 | Entity extraction and graph building |
| **Monitor** | monitor.json | 424 | Feedback collection and RLHF data generation |
| **Orchestrator** | orchestrator.json | 353 | Master router and query classification |
| **Orchestrator TestCopy** | orchestrator_TestCopy.json | 353 | Test version with Chat Trigger |
| **Ingestion TestCopy** | ingestion_TestCopy.json | 506 | Test version with Chat Trigger |
| **Dataset Download** | dataset_download.json | ~400 | Download ML datasets for testing |

---

## Credentials Configuration

Before importing workflows, configure these credentials in n8n (Settings → Credentials).

### 1. PostgreSQL Production

**Name:** `Postgres Production`
**Type:** PostgreSQL
**Used by:** orchestrator, monitor, enrichment, rag_tabular

**Configuration:**
```json
{
  "host": "db.ayqviqmxifzmhphiqfmj.supabase.co",
  "port": 5432,
  "database": "postgres",
  "user": "postgres",
  "password": "[YOUR_SUPABASE_PASSWORD]",
  "ssl": {
    "enabled": true,
    "mode": "require"
  }
}
```

**Environment Variables:**
```bash
POSTGRES_URL=postgresql://postgres:[PASSWORD]@db.ayqviqmxifzmhphiqfmj.supabase.co:5432/postgres
POSTGRES_HOST=db.ayqviqmxifzmhphiqfmj.supabase.co
POSTGRES_PORT=5432
POSTGRES_USER=postgres
POSTGRES_DB=postgres
```

### 2. OpenAI API

**Name:** `OpenAI API Key`
**Type:** HTTP Header Auth
**Used by:** All workflows (LLM calls, embeddings)

**Configuration:**
```json
{
  "name": "Authorization",
  "value": "Bearer sk-proj-fY3g[YOUR_OPENAI_API_KEY]"
}
```

**Environment Variables:**
```bash
OPENAI_API_KEY=sk-proj-fY3g[YOUR_KEY]
LLM_API_URL=https://api.openai.com/v1/chat/completions
EMBEDDING_API_URL=https://api.openai.com/v1/embeddings
DEFAULT_LLM_MODEL=gpt-4-turbo
ROUTER_MODEL=gpt-4o-mini
HYDE_MODEL=gpt-4o
SQL_MODEL=gpt-4o
EMBEDDING_MODEL=text-embedding-3-large
```

### 3. Pinecone API

**Name:** `Pinecone API`
**Type:** HTTP Header Auth
**Used by:** rag_classic, ingestion

**Configuration:**
```json
{
  "name": "Api-Key",
  "value": "pcsk_6GzV[YOUR_PINECONE_API_KEY]"
}
```

**Environment Variables:**
```bash
PINECONE_API_KEY=pcsk_6GzV[YOUR_KEY]
PINECONE_URL=https://n8n-rag-[YOUR_PROJECT_ID].svc.gcp-starter.pinecone.io
PINECONE_INDEX_NAME=n8n-rag
```

**Pinecone Index Configuration:**
- Index Name: `n8n-rag`
- Dimensions: 3072 (for text-embedding-3-large)
- Metric: cosine
- Pod Type: p1.x1 or serverless

### 4. Redis Upstash

**Name:** `Redis Upstash`
**Type:** Redis
**Used by:** orchestrator, all RAG workflows (caching)

**Configuration:**
```json
{
  "host": "dynamic-frog-47846.upstash.io",
  "port": 6379,
  "password": "AbrmAAIncDFlYjliNTA0MzRhNmQ0YjlkYjIzZGM1Y2I2NGJlNDRmMnAxNDc4NDY",
  "ssl": true
}
```

**Environment Variables:**
```bash
REDIS_URL=rediss://:AbrmAAIncDFlYjliNTA0MzRhNmQ0YjlkYjIzZGM1Y2I2NGJlNDRmMnAxNDc4NDY@dynamic-frog-47846.upstash.io:6379
REDIS_HOST=dynamic-frog-47846.upstash.io
REDIS_PORT=6379
REDIS_PASSWORD=AbrmAAIncDFlYjliNTA0MzRhNmQ0YjlkYjIzZGM1Y2I2NGJlNDRmMnAxNDc4NDY
REDIS_TLS=true
```

### 5. Neo4j Graph Database

**Name:** `Neo4j Production`
**Type:** Neo4j
**Used by:** rag_graph, enrichment

**Configuration:**
```json
{
  "url": "neo4j+s://a9a062c3.databases.neo4j.io",
  "username": "neo4j",
  "password": "[YOUR_NEO4J_PASSWORD]",
  "database": "neo4j"
}
```

**Environment Variables:**
```bash
NEO4J_URL=neo4j+s://a9a062c3.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=[YOUR_PASSWORD]
```

### 6. Cohere API (Reranking)

**Name:** `Cohere API`
**Type:** HTTP Header Auth
**Used by:** rag_classic, rag_graph (reranking)

**Configuration:**
```json
{
  "name": "Authorization",
  "value": "Bearer FGnr[YOUR_COHERE_API_KEY]"
}
```

**Environment Variables:**
```bash
COHERE_API_KEY=FGnr[YOUR_KEY]
COHERE_API_URL=https://api.cohere.ai/v1/rerank
RERANKER_MODEL=rerank-multilingual-v3.0
```

### 7. Slack Webhook (Monitoring)

**Name:** `Slack Monitoring`
**Type:** Webhook URL
**Used by:** monitor

**Configuration:**
```json
{
  "url": "https://hooks.slack.com/services/[YOUR]/[WEBHOOK]/[URL]"
}
```

**Environment Variables:**
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/[YOUR]/[WEBHOOK]/[URL]
```

### 8. n8n API (for MCP Skills)

**Name:** `n8n API Token`
**Type:** HTTP Header Auth
**Used by:** External integrations, MCP skills

**Configuration:**
```json
{
  "name": "X-N8N-API-KEY",
  "value": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyMTU3NjdlMC05NThhLTRjNzQtYTY3YS1lMzM1ODA3ZWJhNjQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5MDI2NzQ5fQ.ILpugbzsDXUm856kzHiDg3pWGvaOnTCEIVeTiIgme6Y"
}
```

**Environment Variables:**
```bash
N8N_API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyMTU3NjdlMC05NThhLTRjNzQtYTY3YS1lMzM1ODA3ZWJhNjQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5MDI2NzQ5fQ.ILpugbzsDXUm856kzHiDg3pWGvaOnTCEIVeTiIgme6Y
N8N_URL=https://amoret.app.n8n.cloud
N8N_API_URL=https://amoret.app.n8n.cloud/api/v1
```

---

## Environment Variables

Complete list of all environment variables required by the workflows.

### n8n Configuration

```bash
N8N_URL=https://amoret.app.n8n.cloud
N8N_API_URL=https://amoret.app.n8n.cloud/api/v1
N8N_API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### LLM APIs

```bash
LLM_API_URL=https://api.openai.com/v1/chat/completions
DEFAULT_LLM_MODEL=gpt-4-turbo
ROUTER_MODEL=gpt-4o-mini         # Used by orchestrator for query classification
HYDE_MODEL=gpt-4o                # Used for Hypothetical Document Embeddings
SQL_MODEL=gpt-4o                 # Used by rag_tabular for SQL generation
RERANKER_MODEL=rerank-multilingual-v3.0
```

### Embedding Configuration

```bash
EMBEDDING_API_URL=https://api.openai.com/v1/embeddings
EMBEDDING_MODEL=text-embedding-3-large  # Dimension: 3072
```

### Datastores

```bash
# PostgreSQL (Supabase)
POSTGRES_URL=postgresql://postgres:[PASSWORD]@db.ayqviqmxifzmhphiqfmj.supabase.co:5432/postgres
POSTGRES_HOST=db.ayqviqmxifzmhphiqfmj.supabase.co
POSTGRES_PORT=5432
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=[YOUR_PASSWORD]

# Redis (Upstash)
REDIS_URL=rediss://:AbrmAAIncDFlYjliNTA0MzRhNmQ0YjlkYjIzZGM1Y2I2NGJlNDRmMnAxNDc4NDY@dynamic-frog-47846.upstash.io:6379
REDIS_HOST=dynamic-frog-47846.upstash.io
REDIS_PORT=6379
REDIS_PASSWORD=AbrmAAIncDFlYjliNTA0MzRhNmQ0YjlkYjIzZGM1Y2I2NGJlNDRmMnAxNDc4NDY
REDIS_TLS=true

# Pinecone
PINECONE_API_KEY=pcsk_6GzV[YOUR_KEY]
PINECONE_URL=https://n8n-rag-[PROJECT_ID].svc.gcp-starter.pinecone.io
PINECONE_INDEX_NAME=n8n-rag

# Neo4j
NEO4J_URL=neo4j+s://a9a062c3.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=[YOUR_PASSWORD]

# Cohere
COHERE_API_URL=https://api.cohere.ai/v1/rerank
COHERE_API_KEY=FGnr[YOUR_KEY]
```

### Security & Application

```bash
ALLOWED_ORIGINS=https://amoret.app.n8n.cloud,https://app.company.com
IP_WHITELIST=10.0.0.0/8,192.168.0.0/16
NODE_ENV=production
LOG_LEVEL=info
TENANT_ID=default
```

---

## Database Tables

5 PostgreSQL tables used by the workflows. Schema defined in `scripts/init-db.sql`.

### Table 1: conversation_context

**Purpose:** L2/L3 conversational memory
**Used by:** orchestrator.json (Fetch L2 Memory, Update L2 Memory)

**Schema:**
```sql
CREATE TABLE conversation_context (
    id SERIAL PRIMARY KEY,
    conversation_id VARCHAR(100) NOT NULL,
    tenant_id VARCHAR(50) NOT NULL,
    entities_json JSONB DEFAULT '{}',
    last_intent VARCHAR(50),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(conversation_id, tenant_id)
);

CREATE INDEX idx_conv_ctx_lookup
    ON conversation_context(conversation_id, tenant_id);
```

**Example Row:**
```json
{
  "id": 1,
  "conversation_id": "conv_user123_20260121",
  "tenant_id": "default",
  "entities_json": {
    "person": ["John Doe", "Jane Smith"],
    "organization": ["OpenAI", "Google"],
    "topic": ["machine learning", "neural networks"]
  },
  "last_intent": "QUALITATIVE",
  "updated_at": "2026-01-21T10:30:00Z"
}
```

### Table 2: rlhf_training_data

**Purpose:** RLHF feedback and training data collection
**Used by:** monitor.json (Store Feedback)

**Schema:**
```sql
CREATE TABLE rlhf_training_data (
    id SERIAL PRIMARY KEY,
    conversation_id VARCHAR(100) NOT NULL UNIQUE,
    query TEXT NOT NULL,
    response TEXT NOT NULL,
    feedback_score FLOAT CHECK (feedback_score >= 0 AND feedback_score <= 1),
    feedback_type VARCHAR(50) CHECK (feedback_type IN ('implicit', 'explicit')),
    reasoning_path JSONB,
    is_good_example BOOLEAN DEFAULT false,
    is_bad_example BOOLEAN DEFAULT false,
    needs_review BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_rlhf_quality
    ON rlhf_training_data(is_good_example, is_bad_example)
    WHERE is_good_example = true OR is_bad_example = true;
```

**Example Row:**
```json
{
  "id": 1,
  "conversation_id": "conv_user123_20260121",
  "query": "What is machine learning?",
  "response": "Machine learning is a subset of AI...",
  "feedback_score": 0.95,
  "feedback_type": "implicit",
  "reasoning_path": {
    "classification": "QUALITATIVE",
    "rag_type": "classic",
    "retrieval_count": 5,
    "rerank_applied": true
  },
  "is_good_example": true,
  "is_bad_example": false,
  "needs_review": false,
  "created_at": "2026-01-21T10:30:00Z"
}
```

### Table 3: community_summaries

**Purpose:** Graph community detection results
**Used by:** enrichment.json (Store Communities), rag_graph.json (Retrieve Communities)

**Schema:**
```sql
CREATE TABLE community_summaries (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(50) NOT NULL,
    entity_names TEXT[] NOT NULL,
    summary TEXT NOT NULL,
    relevance_score FLOAT DEFAULT 0.5,
    algorithm VARCHAR(50) DEFAULT 'louvain',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_community_entities
    ON community_summaries USING GIN(entity_names);
```

**Example Row:**
```json
{
  "id": 1,
  "tenant_id": "default",
  "entity_names": ["neural networks", "deep learning", "transformers", "attention mechanism"],
  "summary": "This community represents concepts related to modern deep learning architectures, focusing on attention-based models and neural network fundamentals.",
  "relevance_score": 0.87,
  "algorithm": "louvain",
  "created_at": "2026-01-21T09:00:00Z",
  "updated_at": "2026-01-21T09:00:00Z"
}
```

### Table 4: entities

**Purpose:** Named entity storage for enrichment
**Used by:** enrichment.json (Store Entities), rag_graph.json (Query Entities)

**Schema:**
```sql
CREATE TABLE entities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    tenant_id VARCHAR(50) NOT NULL,
    confidence FLOAT DEFAULT 0.5,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(name, tenant_id)
);

CREATE INDEX idx_entities_lookup ON entities(name, tenant_id);
CREATE INDEX idx_entities_type ON entities(type, tenant_id);
```

**Entity Types:**
- PERSON
- ORGANIZATION
- LOCATION
- DATE
- TECHNOLOGY
- CONCEPT

**Example Rows:**
```json
[
  {
    "id": 1,
    "name": "GPT-4",
    "type": "TECHNOLOGY",
    "tenant_id": "default",
    "confidence": 0.95,
    "created_at": "2026-01-21T09:00:00Z"
  },
  {
    "id": 2,
    "name": "OpenAI",
    "type": "ORGANIZATION",
    "tenant_id": "default",
    "confidence": 0.98,
    "created_at": "2026-01-21T09:00:00Z"
  }
]
```

### Table 5: documents

**Purpose:** Main document storage with versioning
**Used by:** ingestion.json (Store Documents), all RAG workflows (Retrieve Documents)

**Schema:**
```sql
CREATE TABLE documents (
    id VARCHAR(100) PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    tenant_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    is_obsolete BOOLEAN DEFAULT FALSE,
    obsoleted_at TIMESTAMP,
    superseded_by VARCHAR(100),
    version INT DEFAULT 1,
    summary_context TEXT,
    quality_score FLOAT DEFAULT 0.5,
    parent_id VARCHAR(100),
    parent_filename VARCHAR(500),
    chunk_method VARCHAR(50)
);

CREATE INDEX idx_docs_obsolete
    ON documents(is_obsolete, tenant_id)
    WHERE is_obsolete = false;

CREATE INDEX idx_docs_parent
    ON documents(parent_filename, version)
    WHERE is_obsolete = false;

CREATE INDEX idx_docs_tenant
    ON documents(tenant_id, created_at);
```

**Example Row:**
```json
{
  "id": "doc_20260121_001_chunk_0",
  "content": "Machine learning is a subset of artificial intelligence...",
  "metadata": {
    "source": "ml_textbook.pdf",
    "page": 15,
    "section": "Introduction to ML"
  },
  "tenant_id": "default",
  "created_at": "2026-01-21T08:00:00Z",
  "is_obsolete": false,
  "obsoleted_at": null,
  "superseded_by": null,
  "version": 1,
  "summary_context": "Introduction to machine learning concepts",
  "quality_score": 0.89,
  "parent_id": "doc_20260121_001",
  "parent_filename": "ml_textbook.pdf",
  "chunk_method": "semantic"
}
```

---

## 1. RAG Classic Workflow

**File:** `workflows/rag_classic.json`
**Lines:** 346
**Purpose:** Vector-based retrieval using Pinecone similarity search

### Architecture

```
Query Input
    ↓
[HyDE Generation] ← Generate hypothetical document (GPT-4o)
    ↓
[Embedding] ← Convert to vector (text-embedding-3-large)
    ↓
[Pinecone Search] ← Vector similarity search (top-k)
    ↓
[Reranking] ← Cohere rerank-multilingual-v3.0
    ↓
[Context Assembly] ← Prepare context for LLM
    ↓
[LLM Generation] ← Generate response (GPT-4-turbo)
    ↓
Response Output
```

### Node Breakdown

#### Node 1: Webhook Entry / Chat Trigger
- **Type:** `n8n-nodes-base.webhook` (production) or `@n8n/n8n-nodes-langchain.chatTrigger` (TestCopy)
- **Path:** `/webhook/rag-classic`
- **Method:** POST
- **Input Schema:**
```json
{
  "query": "string (required)",
  "user_id": "string (required)",
  "tenant_id": "string (optional, default: 'default')",
  "conversation_id": "string (optional)",
  "top_k": "number (optional, default: 5)"
}
```

#### Node 2: HyDE Generation
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Generate hypothetical document for better retrieval
- **API:** OpenAI Chat Completions
- **Credential:** OpenAI API Key
- **Configuration:**
```json
{
  "method": "POST",
  "url": "{{ $env.LLM_API_URL }}",
  "authentication": "predefinedCredentialType",
  "nodeCredentialType": "openAiApi",
  "sendBody": true,
  "bodyParameters": {
    "model": "{{ $env.HYDE_MODEL }}",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful assistant. Generate a hypothetical document that would contain the answer to the user's query."
      },
      {
        "role": "user",
        "content": "{{ $json.query }}"
      }
    ],
    "temperature": 0.3,
    "max_tokens": 200
  }
}
```

#### Node 3: Generate Embedding
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Convert HyDE document to vector embedding
- **API:** OpenAI Embeddings
- **Credential:** OpenAI API Key
- **Configuration:**
```json
{
  "method": "POST",
  "url": "{{ $env.EMBEDDING_API_URL }}",
  "authentication": "predefinedCredentialType",
  "nodeCredentialType": "openAiApi",
  "sendBody": true,
  "bodyParameters": {
    "model": "{{ $env.EMBEDDING_MODEL }}",
    "input": "{{ $json.hyde_document }}"
  }
}
```
- **Output:** Vector of dimension 3072

#### Node 4: Pinecone Search
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Search similar vectors in Pinecone
- **API:** Pinecone Query
- **Credential:** Pinecone API
- **Configuration:**
```json
{
  "method": "POST",
  "url": "{{ $env.PINECONE_URL }}/query",
  "authentication": "predefinedCredentialType",
  "nodeCredentialType": "pineconeApi",
  "sendBody": true,
  "bodyParameters": {
    "vector": "{{ $json.embedding }}",
    "topK": "{{ $json.top_k || 10 }}",
    "includeMetadata": true,
    "namespace": "{{ $json.tenant_id }}"
  }
}
```
- **Output:** Top-k most similar documents with scores

#### Node 5: Fetch Documents from PostgreSQL
- **Type:** `n8n-nodes-base.postgres`
- **Purpose:** Retrieve full document content by IDs
- **Credential:** Postgres Production
- **Query:**
```sql
SELECT id, content, metadata, quality_score, summary_context
FROM documents
WHERE id = ANY($1::varchar[])
  AND tenant_id = $2
  AND is_obsolete = false
ORDER BY array_position($1::varchar[], id);
```
- **Parameters:**
  - `$1`: Array of document IDs from Pinecone
  - `$2`: tenant_id

#### Node 6: Cohere Reranking
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Rerank documents for better relevance
- **API:** Cohere Rerank
- **Credential:** Cohere API
- **Configuration:**
```json
{
  "method": "POST",
  "url": "{{ $env.COHERE_API_URL }}",
  "authentication": "predefinedCredentialType",
  "nodeCredentialType": "cohereApi",
  "sendBody": true,
  "bodyParameters": {
    "model": "{{ $env.RERANKER_MODEL }}",
    "query": "{{ $json.query }}",
    "documents": "{{ $json.documents.map(d => d.content) }}",
    "top_n": 5,
    "return_documents": true
  }
}
```

#### Node 7: Context Assembly
- **Type:** `n8n-nodes-base.code`
- **Purpose:** Format retrieved documents into context
- **JavaScript Code:**
```javascript
const documents = $input.all();
const query = $('Webhook Entry').first().json.query;

// Assemble context from reranked documents
const context = documents
  .map((doc, idx) => {
    const score = doc.json.relevance_score || 0;
    const content = doc.json.document?.content || doc.json.content;
    return `[Document ${idx + 1}] (Relevance: ${score.toFixed(3)})\n${content}`;
  })
  .join('\n\n---\n\n');

return [{
  json: {
    query,
    context,
    document_count: documents.length
  }
}];
```

#### Node 8: LLM Response Generation
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Generate final response using retrieved context
- **API:** OpenAI Chat Completions
- **Credential:** OpenAI API Key
- **Configuration:**
```json
{
  "method": "POST",
  "url": "{{ $env.LLM_API_URL }}",
  "authentication": "predefinedCredentialType",
  "nodeCredentialType": "openAiApi",
  "sendBody": true,
  "bodyParameters": {
    "model": "{{ $env.DEFAULT_LLM_MODEL }}",
    "messages": [
      {
        "role": "system",
        "content": "You are a helpful AI assistant. Answer the user's question using the provided context. Be accurate and cite sources when possible."
      },
      {
        "role": "user",
        "content": "Context:\n{{ $json.context }}\n\nQuestion: {{ $json.query }}\n\nAnswer:"
      }
    ],
    "temperature": 0.7,
    "max_tokens": 1000
  }
}
```

#### Node 9: Response Formatter
- **Type:** `n8n-nodes-base.code`
- **Purpose:** Format final response
- **Output Schema:**
```json
{
  "status": "success",
  "response": "string",
  "sources": [
    {
      "id": "doc_id",
      "relevance_score": 0.95,
      "summary": "string"
    }
  ],
  "retrieval_method": "classic_rag",
  "document_count": 5,
  "execution_time_ms": 1234
}
```

### Credentials Required

1. **OpenAI API Key** - For HyDE, embeddings, and LLM generation
2. **Pinecone API** - For vector similarity search
3. **Cohere API** - For reranking
4. **Postgres Production** - For document retrieval

### Environment Variables Used

```bash
LLM_API_URL
HYDE_MODEL=gpt-4o
EMBEDDING_API_URL
EMBEDDING_MODEL=text-embedding-3-large
PINECONE_URL
PINECONE_INDEX_NAME
DEFAULT_LLM_MODEL=gpt-4-turbo
COHERE_API_URL
RERANKER_MODEL=rerank-multilingual-v3.0
```

### Testing

**Test with Chat Trigger (TestCopy):**
```
Query: "What is machine learning?"
Expected: Response with 5 sources from vector search
```

**Test with Webhook (Production):**
```bash
curl -X POST "https://amoret.app.n8n.cloud/webhook/rag-classic" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Explain neural networks",
    "user_id": "test_user",
    "tenant_id": "default",
    "top_k": 5
  }'
```

---

## 2. RAG Graph Workflow

**File:** `workflows/rag_graph.json`
**Lines:** 419
**Purpose:** Graph-based retrieval using Neo4j entity relationships

### Architecture

```
Query Input
    ↓
[Entity Extraction] ← Extract entities from query (GPT-4o-mini)
    ↓
[Neo4j Search] ← Find related entities and communities
    ↓
[Community Retrieval] ← Fetch community summaries (PostgreSQL)
    ↓
[Document Retrieval] ← Get documents linked to entities
    ↓
[Context Assembly] ← Build graph-aware context
    ↓
[LLM Generation] ← Generate response (GPT-4-turbo)
    ↓
Response Output
```

### Node Breakdown

#### Node 1: Webhook Entry
- **Type:** `n8n-nodes-base.webhook`
- **Path:** `/webhook/rag-graph`
- **Input Schema:**
```json
{
  "query": "string (required)",
  "user_id": "string (required)",
  "tenant_id": "string (optional)",
  "conversation_id": "string (optional)",
  "max_hops": "number (optional, default: 2)"
}
```

#### Node 2: Entity Extraction
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Extract named entities from query
- **API:** OpenAI Chat Completions
- **Prompt:**
```
Extract all named entities from the following query.
Return as JSON array with fields: name, type.
Types: PERSON, ORGANIZATION, TECHNOLOGY, CONCEPT, LOCATION, DATE.

Query: {{ $json.query }}
```
- **Output Example:**
```json
{
  "entities": [
    {"name": "transformers", "type": "TECHNOLOGY"},
    {"name": "attention mechanism", "type": "CONCEPT"}
  ]
}
```

#### Node 3: Neo4j Entity Search
- **Type:** `n8n-nodes-base.neo4j`
- **Purpose:** Find related entities in knowledge graph
- **Credential:** Neo4j Production
- **Cypher Query:**
```cypher
MATCH (e:Entity)
WHERE e.name IN $entity_names
  AND e.tenant_id = $tenant_id
OPTIONAL MATCH (e)-[r*1..2]-(related:Entity)
WHERE related.tenant_id = $tenant_id
RETURN e, collect(DISTINCT related) AS related_entities, collect(DISTINCT type(r)) AS relationship_types
ORDER BY size(related_entities) DESC
LIMIT 20
```
- **Parameters:**
  - `$entity_names`: Array of extracted entity names
  - `$tenant_id`: Tenant identifier

#### Node 4: Community Retrieval
- **Type:** `n8n-nodes-base.postgres`
- **Purpose:** Fetch community summaries for entities
- **Credential:** Postgres Production
- **Query:**
```sql
SELECT id, entity_names, summary, relevance_score, algorithm
FROM community_summaries
WHERE tenant_id = $1
  AND entity_names && $2::text[]
ORDER BY relevance_score DESC
LIMIT 5;
```
- **Parameters:**
  - `$1`: tenant_id
  - `$2`: Array of entity names

#### Node 5: Entity Document Mapping
- **Type:** `n8n-nodes-base.postgres`
- **Purpose:** Find documents containing the entities
- **Query:**
```sql
SELECT DISTINCT d.id, d.content, d.metadata, d.quality_score
FROM documents d, entities e
WHERE d.tenant_id = $1
  AND e.tenant_id = $1
  AND e.name = ANY($2::varchar[])
  AND d.metadata->>'entities' ? e.name
  AND d.is_obsolete = false
ORDER BY d.quality_score DESC
LIMIT 10;
```

#### Node 6: Graph Context Assembly
- **Type:** `n8n-nodes-base.code`
- **Purpose:** Build context with entity relationships
- **JavaScript Code:**
```javascript
const entities = $('Entity Extraction').first().json.entities;
const graph_data = $('Neo4j Entity Search').all();
const communities = $('Community Retrieval').all();
const documents = $('Entity Document Mapping').all();

// Build entity relationship map
const entity_map = {};
graph_data.forEach(item => {
  const entity = item.json.e;
  const related = item.json.related_entities || [];
  entity_map[entity.name] = {
    type: entity.type,
    related: related.map(r => r.name),
    relationships: item.json.relationship_types || []
  };
});

// Build community context
const community_context = communities
  .map(c => `[Community] ${c.json.summary}`)
  .join('\n\n');

// Build document context
const document_context = documents
  .map((d, idx) => `[Document ${idx + 1}] ${d.json.content}`)
  .join('\n\n---\n\n');

// Assemble full context
const context = `
=== Entity Relationships ===
${JSON.stringify(entity_map, null, 2)}

=== Community Summaries ===
${community_context}

=== Related Documents ===
${document_context}
`;

return [{
  json: {
    query: $('Webhook Entry').first().json.query,
    context,
    entity_count: entities.length,
    document_count: documents.length
  }
}];
```

#### Node 7: LLM Response Generation
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Generate response using graph context
- **API:** OpenAI Chat Completions
- **System Prompt:**
```
You are a knowledge graph assistant. Answer the user's question using the provided entity relationships, community summaries, and documents. Explain how entities are related when relevant.
```

#### Node 8: Response Formatter
- **Output Schema:**
```json
{
  "status": "success",
  "response": "string",
  "entities": [
    {
      "name": "transformers",
      "type": "TECHNOLOGY",
      "related_entities": ["attention mechanism", "neural networks"]
    }
  ],
  "communities": [
    {
      "summary": "string",
      "relevance_score": 0.87
    }
  ],
  "retrieval_method": "graph_rag",
  "entity_count": 3,
  "document_count": 5
}
```

### Credentials Required

1. **OpenAI API Key** - For entity extraction and LLM generation
2. **Neo4j Production** - For knowledge graph queries
3. **Postgres Production** - For community and document retrieval

### Environment Variables Used

```bash
LLM_API_URL
ROUTER_MODEL=gpt-4o-mini        # For entity extraction
DEFAULT_LLM_MODEL=gpt-4-turbo   # For response generation
NEO4J_URL
NEO4J_USERNAME
NEO4J_PASSWORD
```

### Testing

```bash
curl -X POST "https://amoret.app.n8n.cloud/webhook/rag-graph" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What are the relationships between transformers and attention mechanisms?",
    "user_id": "test_user",
    "tenant_id": "default",
    "max_hops": 2
  }'
```

---

## 3. RAG Tabular Workflow

**File:** `workflows/rag_tabular.json`
**Lines:** 416
**Purpose:** SQL-based retrieval for quantitative/tabular queries

### Architecture

```
Query Input
    ↓
[Query Classification] ← Determine if SQL-compatible (GPT-4o-mini)
    ↓
[SQL Generation] ← Generate SQL query (GPT-4o)
    ↓
[SQL Validation] ← Validate syntax and safety
    ↓
[Query Execution] ← Run SQL on PostgreSQL
    ↓
[Result Processing] ← Format results
    ↓
[LLM Explanation] ← Generate natural language response (GPT-4-turbo)
    ↓
Response Output
```

### Node Breakdown

#### Node 1: Webhook Entry
- **Type:** `n8n-nodes-base.webhook`
- **Path:** `/webhook/rag-tabular`
- **Input Schema:**
```json
{
  "query": "string (required)",
  "user_id": "string (required)",
  "tenant_id": "string (optional)",
  "conversation_id": "string (optional)"
}
```

#### Node 2: Query Classification
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Determine if query requires SQL
- **API:** OpenAI Chat Completions
- **Model:** gpt-4o-mini
- **Prompt:**
```
Classify if the following query requires SQL database queries to answer.
Queries requiring SQL typically ask for:
- Quantitative data (averages, sums, counts)
- Comparisons over time
- Statistical analysis
- Tabular data lookups

Return JSON: {"requires_sql": boolean, "reason": "string"}

Query: {{ $json.query }}
```

#### Node 3: Schema Retrieval
- **Type:** `n8n-nodes-base.postgres`
- **Purpose:** Get database schema for SQL generation
- **Credential:** Postgres Production
- **Query:**
```sql
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('documents', 'entities', 'rlhf_training_data', 'conversation_context', 'community_summaries')
ORDER BY table_name, ordinal_position;
```

#### Node 4: SQL Generation
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Generate SQL query from natural language
- **API:** OpenAI Chat Completions
- **Model:** gpt-4o (SQL_MODEL)
- **System Prompt:**
```
You are a SQL expert. Generate a PostgreSQL query to answer the user's question.

Database Schema:
{{ $json.schema }}

Rules:
1. Use only SELECT statements (no INSERT, UPDATE, DELETE, DROP)
2. Always include tenant_id filter: WHERE tenant_id = 'default'
3. Limit results to reasonable size (LIMIT 100)
4. Use proper JOIN syntax when combining tables
5. Return only the SQL query, no explanation

User Question: {{ $json.query }}
```

#### Node 5: SQL Validation
- **Type:** `n8n-nodes-base.code`
- **Purpose:** Validate SQL for safety
- **JavaScript Code:**
```javascript
const sql = $json.sql_query;

// Safety checks
const dangerous_keywords = ['DROP', 'DELETE', 'UPDATE', 'INSERT', 'ALTER', 'CREATE', 'TRUNCATE', 'GRANT', 'REVOKE'];
const sql_upper = sql.toUpperCase();

for (const keyword of dangerous_keywords) {
  if (sql_upper.includes(keyword)) {
    throw new Error(`Dangerous SQL keyword detected: ${keyword}`);
  }
}

// Check for SELECT statement
if (!sql_upper.trim().startsWith('SELECT')) {
  throw new Error('Only SELECT queries are allowed');
}

// Check for tenant_id filter
if (!sql_upper.includes('TENANT_ID')) {
  throw new Error('Query must include tenant_id filter for security');
}

return [{
  json: {
    sql_query: sql,
    validation: 'passed',
    query: $json.query
  }
}];
```

#### Node 6: SQL Execution
- **Type:** `n8n-nodes-base.postgres`
- **Purpose:** Execute validated SQL query
- **Credential:** Postgres Production
- **Query:** `{{ $json.sql_query }}`
- **Parameters:** Dynamic based on generated SQL

#### Node 7: Result Processing
- **Type:** `n8n-nodes-base.code`
- **Purpose:** Format SQL results for LLM
- **JavaScript Code:**
```javascript
const results = $input.all();
const query = $('Webhook Entry').first().json.query;
const sql = $('SQL Generation').first().json.sql_query;

// Convert results to markdown table
const formatTable = (data) => {
  if (data.length === 0) return 'No results found.';

  const headers = Object.keys(data[0]);
  const headerRow = '| ' + headers.join(' | ') + ' |';
  const separatorRow = '|' + headers.map(() => '---').join('|') + '|';
  const dataRows = data.map(row =>
    '| ' + headers.map(h => row[h]).join(' | ') + ' |'
  ).join('\n');

  return `${headerRow}\n${separatorRow}\n${dataRows}`;
};

const results_table = formatTable(results.map(r => r.json));

return [{
  json: {
    query,
    sql_query: sql,
    results_count: results.length,
    results_table,
    raw_results: results.map(r => r.json)
  }
}];
```

#### Node 8: LLM Explanation
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Generate natural language explanation
- **API:** OpenAI Chat Completions
- **Model:** gpt-4-turbo
- **System Prompt:**
```
You are a data analyst. Explain the SQL query results in natural language, answering the user's question.

SQL Query:
{{ $json.sql_query }}

Results:
{{ $json.results_table }}

User Question: {{ $json.query }}

Provide a clear, concise answer with insights from the data.
```

#### Node 9: Response Formatter
- **Output Schema:**
```json
{
  "status": "success",
  "response": "string (natural language explanation)",
  "sql_query": "string (executed SQL)",
  "results": [
    { ... }
  ],
  "results_count": 10,
  "retrieval_method": "tabular_rag",
  "execution_time_ms": 234
}
```

### Credentials Required

1. **OpenAI API Key** - For query classification, SQL generation, and explanation
2. **Postgres Production** - For schema retrieval and SQL execution

### Environment Variables Used

```bash
LLM_API_URL
ROUTER_MODEL=gpt-4o-mini        # For query classification
SQL_MODEL=gpt-4o                # For SQL generation
DEFAULT_LLM_MODEL=gpt-4-turbo   # For natural language explanation
```

### Testing

```bash
curl -X POST "https://amoret.app.n8n.cloud/webhook/rag-tabular" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is the average feedback score for queries about machine learning?",
    "user_id": "test_user",
    "tenant_id": "default"
  }'
```

---

---

## 9. Dataset Download Workflow

**File:** `workflows/dataset_download.json`
**Purpose:** Download and manage ML evaluation datasets for testing and improving the RAG system

### Architecture

```
User Input (Webhook/Chat)
    ↓
[Dataset Registry] ← 13 datasets defined
    ↓
[Command Parser] ← Parse: list, download, status, trigger-github
    ↓
[Command Switch]
    ├─→ [List Datasets] → Display all available datasets
    ├─→ [Prepare Download] → HTTP downloads
    ├─→ [Check Status] → Show download status
    └─→ [Trigger GitHub Action] → Full git clone downloads
         ↓
[Format Response] → Return formatted result
```

### Available Datasets

| ID | Name | Type | Description |
|:---|:-----|:-----|:------------|
| `bbh` | BIG-Bench Hard | Git | Challenging reasoning tasks |
| `spider2` | Spider2 SQL | Git | SQL/database understanding tasks |
| `hotpotqa` | HotpotQA | HTTP | Multi-hop question answering |
| `musique` | MuSiQue | Git | Multi-step reasoning |
| `strategyqa` | StrategyQA | Git | Strategic reasoning |
| `msmarco` | MS MARCO | HTTP | Large-scale ranking dataset |
| `tabfact` | Table Fact Checking | Git | Tabular data verification |
| `gsm8k` | GSM8K | Git | Grade school math problems |
| `squad` | SQuAD 2.0 | HTTP | Reading comprehension |
| `pubmedqa` | PubMedQA | Git | Biomedical QA |
| `wikihop` | WikiHop | HTTP | Knowledge-based QA |
| `climatefever` | Climate FEVER | Git | Climate claims verification |
| `reranker` | BGE Reranker Data | HTTP | Training data for reranking |

### Commands

| Command | Description |
|:--------|:------------|
| `list` | Display all available datasets |
| `download <id>` | Download a specific dataset (HTTP files only) |
| `download all` | Download all HTTP-accessible files |
| `status` | Check download status |
| `trigger-github` | Trigger GitHub Action for full downloads (including git clones) |

### Node Breakdown

#### Node 1: Webhook Entry / Chat Trigger
- **Type:** `n8n-nodes-base.webhook` / `@n8n/n8n-nodes-langchain.chatTrigger`
- **Path:** `/webhook/dataset-download`
- **Method:** POST
- **Input Schema:**
```json
{
  "command": "string (list|download|status|trigger-github)",
  "action": "string (alternative to command)",
  "dataset": "string (optional, dataset ID)"
}
```

#### Node 2: Dataset Registry
- **Type:** `n8n-nodes-base.code`
- **Purpose:** Define all available datasets
- **Output:** Object containing all 13 dataset definitions

#### Node 3: Command Parser
- **Type:** `n8n-nodes-base.code`
- **Purpose:** Parse user input and extract command/arguments

#### Node 4: Command Switch
- **Type:** `n8n-nodes-base.switch`
- **Purpose:** Route to appropriate handler based on command

#### Node 5: HTTP Download
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Download HTTP-accessible files
- **Timeout:** 120 seconds

#### Node 6: Trigger GitHub Action
- **Type:** `n8n-nodes-base.httpRequest`
- **Purpose:** Trigger the `download_datasets.yml` workflow via GitHub API
- **API:** `POST /repos/{owner}/{repo}/actions/workflows/{workflow_id}/dispatches`
- **Credential:** GitHub Token (requires `repo` and `workflow` permissions)

### Credentials Required

1. **GitHub Token** (optional) - For triggering GitHub Actions
   - Required permissions: `repo`, `workflow`
   - Header: `Authorization: Bearer <token>`

### Environment Variables

```bash
# GitHub (optional, for GitHub Actions trigger)
GITHUB_TOKEN=ghp_xxxxxxxxxxxxx
GITHUB_OWNER=LBJLincoln
GITHUB_REPO=PROJET_N8N_ULTIMATE
```

### Testing

**Via Chat Trigger:**
```
list              → Shows all 13 datasets
download hotpotqa → Downloads HotpotQA files
download all      → Downloads all HTTP files
trigger-github    → Triggers full download via GitHub Actions
```

**Via Webhook:**
```bash
# List datasets
curl -X POST "https://amoret.app.n8n.cloud/webhook/dataset-download" \
  -H "Content-Type: application/json" \
  -d '{"command": "list"}'

# Download specific dataset
curl -X POST "https://amoret.app.n8n.cloud/webhook/dataset-download" \
  -H "Content-Type: application/json" \
  -d '{"command": "download", "dataset": "squad"}'

# Trigger GitHub Action
curl -X POST "https://amoret.app.n8n.cloud/webhook/dataset-download" \
  -H "Content-Type: application/json" \
  -d '{"command": "trigger-github"}'
```

### GitHub Actions Integration

The workflow can trigger the GitHub Action defined in `.github/workflows/download_datasets.yml`:

1. **Manual trigger** via GitHub UI (workflow_dispatch)
2. **API trigger** via n8n workflow (requires GitHub token)
3. **Artifacts**: Downloaded datasets are available as workflow artifacts for 7 days

---

**CONTINUED IN NEXT RESPONSE DUE TO LENGTH...**

*This document continues with detailed documentation for:*
- 4. Ingestion Workflow
- 5. Enrichment Workflow
- 6. Monitor Workflow
- 7. Orchestrator Workflow
- 8. TestCopy Workflows
- 10. Workflow Dependencies

Would you like me to continue with the remaining workflows?
