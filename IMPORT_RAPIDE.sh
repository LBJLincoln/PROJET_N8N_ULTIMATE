#!/bin/bash
#
# 🚀 IMPORT RAPIDE DES WORKFLOWS N8N
# Copiez-collez ce script complet dans votre terminal
#

set -e

# Configuration
N8N_API_URL="${N8N_API_URL:-https://amoret.app.n8n.cloud}"
N8N_API_KEY="${N8N_API_KEY}"

echo "============================================================"
echo "🚀 Import Rapide des Workflows n8n"
echo "============================================================"
echo "Instance: $N8N_API_URL"
echo ""

# Vérifier l'API key
if [ -z "$N8N_API_KEY" ]; then
    echo "❌ ERROR: N8N_API_KEY non définie"
    echo ""
    echo "Configurez votre API key d'abord:"
    echo "  export N8N_API_KEY='votre-api-key-ici'"
    echo ""
    echo "Votre API key actuelle:"
    echo "  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIyMTU3NjdlMC05NThhLTRjNzQtYTY3YS1lMzM1ODA3ZWJhNjQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzY5MDI2NzQ5fQ.ILpugbzsDXUm856kzHiDg3pWGvaOnTCEIVeTiIgme6Y"
    exit 1
fi

# Fonction d'import
import_workflow() {
    local workflow_file="$1"
    local workflow_name=$(basename "$workflow_file" .json)

    echo -n "📝 Import $workflow_name... "

    local response=$(curl -s -w "\n%{http_code}" \
        -X POST "${N8N_API_URL}/api/v1/workflows" \
        -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
        -H "Content-Type: application/json" \
        -d @"$workflow_file")

    local http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "✅ OK"
        return 0
    else
        echo "❌ Erreur (HTTP $http_code)"
        return 1
    fi
}

# Créer dossier temporaire
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

echo "📥 Téléchargement des workflows depuis GitHub..."

# URLs des workflows (raw GitHub)
BASE_URL="https://raw.githubusercontent.com/LBJLincoln/PROJET_N8N_ULTIMATE/claude/import-json-workflows-oUTSl/workflows"

workflows=(
    "orchestrator_TestCopy.json"
    "ingestion_TestCopy.json"
    "orchestrator.json"
    "ingestion.json"
    "rag_graph.json"
    "rag_classic.json"
    "rag_tabular.json"
    "enrichment.json"
    "monitor.json"
)

# Télécharger les workflows
for wf in "${workflows[@]}"; do
    echo -n "  Télécharge $wf... "
    if curl -sSL "${BASE_URL}/${wf}" -o "$wf" 2>/dev/null; then
        echo "✅"
    else
        echo "❌ Erreur téléchargement"
    fi
done

echo ""
echo "🚀 Import des workflows dans n8n..."
echo ""

# Importer les workflows
success=0
total=${#workflows[@]}

for wf in "${workflows[@]}"; do
    if [ -f "$wf" ]; then
        if import_workflow "$wf"; then
            ((success++))
        fi
    fi
done

# Nettoyage
cd - > /dev/null
rm -rf "$TMPDIR"

echo ""
echo "============================================================"
echo "✅ Import terminé: $success/$total workflows importés"
echo "============================================================"

exit 0
