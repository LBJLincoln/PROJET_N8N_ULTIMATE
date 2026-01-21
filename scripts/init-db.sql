-- ============================================
-- N8N MCP ULTIMATE - Database Initialization
-- ============================================
-- Generated: 2026-01-21
-- Session: claude/setup-n8n-mcp-skills-onKkM
-- Description: Creates all required tables and indexes for RAG system

-- ============================================
-- 1. CONVERSATION CONTEXT (L2/L3 Memory)
-- ============================================
CREATE TABLE IF NOT EXISTS conversation_context (
    id SERIAL PRIMARY KEY,
    conversation_id VARCHAR(100) NOT NULL,
    tenant_id VARCHAR(50) NOT NULL,
    entities_json JSONB DEFAULT '{}',
    last_intent VARCHAR(50),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(conversation_id, tenant_id)
);

CREATE INDEX IF NOT EXISTS idx_conv_ctx_lookup 
    ON conversation_context(conversation_id, tenant_id);

COMMENT ON TABLE conversation_context IS 'Stores conversation context and extracted entities for L2/L3 memory';
COMMENT ON COLUMN conversation_context.entities_json IS 'JSONB field containing extracted entities from conversation';

-- ============================================
-- 2. RLHF TRAINING DATA
-- ============================================
CREATE TABLE IF NOT EXISTS rlhf_training_data (
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

CREATE INDEX IF NOT EXISTS idx_rlhf_quality 
    ON rlhf_training_data(is_good_example, is_bad_example) 
    WHERE is_good_example = true OR is_bad_example = true;

COMMENT ON TABLE rlhf_training_data IS 'Stores RLHF training data with feedback scores';
COMMENT ON COLUMN rlhf_training_data.reasoning_path IS 'JSONB containing the reasoning steps taken';

-- ============================================
-- 3. COMMUNITY SUMMARIES
-- ============================================
CREATE TABLE IF NOT EXISTS community_summaries (
    id SERIAL PRIMARY KEY,
    tenant_id VARCHAR(50) NOT NULL,
    entity_names TEXT[] NOT NULL,
    summary TEXT NOT NULL,
    relevance_score FLOAT DEFAULT 0.5,
    algorithm VARCHAR(50) DEFAULT 'louvain',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_community_entities 
    ON community_summaries USING GIN(entity_names);

COMMENT ON TABLE community_summaries IS 'Stores community detection summaries from graph analysis';
COMMENT ON COLUMN community_summaries.algorithm IS 'Community detection algorithm used (louvain, etc.)';

-- ============================================
-- 4. ENTITIES (for enrichment)
-- ============================================
CREATE TABLE IF NOT EXISTS entities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    tenant_id VARCHAR(50) NOT NULL,
    confidence FLOAT DEFAULT 0.5,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(name, tenant_id)
);

CREATE INDEX IF NOT EXISTS idx_entities_lookup 
    ON entities(name, tenant_id);

CREATE INDEX IF NOT EXISTS idx_entities_type 
    ON entities(type, tenant_id);

COMMENT ON TABLE entities IS 'Stores extracted entities from documents for enrichment';
COMMENT ON COLUMN entities.confidence IS 'Confidence score of entity extraction (0-1)';

-- ============================================
-- 5. DOCUMENTS TABLE (modifications)
-- ============================================
-- Create documents table if it doesn't exist
CREATE TABLE IF NOT EXISTS documents (
    id VARCHAR(100) PRIMARY KEY,
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    tenant_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add new columns for versioning and quality
ALTER TABLE documents ADD COLUMN IF NOT EXISTS is_obsolete BOOLEAN DEFAULT FALSE;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS obsoleted_at TIMESTAMP;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS superseded_by VARCHAR(100);
ALTER TABLE documents ADD COLUMN IF NOT EXISTS version INT DEFAULT 1;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS summary_context TEXT;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS quality_score FLOAT DEFAULT 0.5;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS parent_id VARCHAR(100);
ALTER TABLE documents ADD COLUMN IF NOT EXISTS parent_filename VARCHAR(500);
ALTER TABLE documents ADD COLUMN IF NOT EXISTS chunk_method VARCHAR(50);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_docs_obsolete 
    ON documents(is_obsolete, tenant_id) 
    WHERE is_obsolete = false;

CREATE INDEX IF NOT EXISTS idx_docs_parent 
    ON documents(parent_filename, version) 
    WHERE is_obsolete = false;

CREATE INDEX IF NOT EXISTS idx_docs_tenant 
    ON documents(tenant_id, created_at);

COMMENT ON TABLE documents IS 'Main documents table with versioning and quality tracking';
COMMENT ON COLUMN documents.is_obsolete IS 'Marks if document has been superseded by newer version';
COMMENT ON COLUMN documents.quality_score IS 'Quality score of document content (0-1)';

-- ============================================
-- VERIFICATION
-- ============================================
-- Count tables created
SELECT 
    'conversation_context' as table_name, 
    COUNT(*) as row_count 
FROM conversation_context
UNION ALL
SELECT 
    'rlhf_training_data' as table_name, 
    COUNT(*) as row_count 
FROM rlhf_training_data
UNION ALL
SELECT 
    'community_summaries' as table_name, 
    COUNT(*) as row_count 
FROM community_summaries
UNION ALL
SELECT 
    'entities' as table_name, 
    COUNT(*) as row_count 
FROM entities
UNION ALL
SELECT 
    'documents' as table_name, 
    COUNT(*) as row_count 
FROM documents;

-- Show all indexes
SELECT 
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename IN (
    'conversation_context',
    'rlhf_training_data',
    'community_summaries',
    'entities',
    'documents'
)
ORDER BY tablename, indexname;
