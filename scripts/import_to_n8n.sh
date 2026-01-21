#!/bin/bash
#
# Import n8n workflows to instance via API
# Usage: ./import_to_n8n.sh [--all | workflow1.json workflow2.json ...]
#

set -e

# Configuration
N8N_API_URL="${N8N_API_URL:-https://amoret.app.n8n.cloud}"
N8N_API_KEY="${N8N_API_KEY}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================"
echo "n8n Workflow Import Script"
echo "============================================================"
echo "Instance: $N8N_API_URL"
echo ""

# Check if API key is set
if [ -z "$N8N_API_KEY" ]; then
    echo -e "${RED}✗ Error: N8N_API_KEY environment variable is not set${NC}"
    echo ""
    echo "Please set your n8n API key:"
    echo "  export N8N_API_KEY='your-api-key-here'"
    echo ""
    echo "You can find your API key at:"
    echo "  ${N8N_API_URL}/settings/api"
    exit 1
fi

# Function to import a single workflow
import_workflow() {
    local workflow_file="$1"
    local workflow_name=$(basename "$workflow_file" .json)

    echo -n "📝 Importing $workflow_name... "

    # Read workflow JSON
    local workflow_data=$(cat "$workflow_file")

    # Import via API
    local response=$(curl -s -w "\n%{http_code}" \
        -X POST "${N8N_API_URL}/api/v1/workflows" \
        -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$workflow_data")

    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        local workflow_id=$(echo "$body" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo -e "${GREEN}✓ Success${NC} (ID: $workflow_id)"
        return 0
    else
        echo -e "${RED}✗ Failed${NC} (HTTP $http_code)"
        echo "$body" | head -3
        return 1
    fi
}

# Main logic
cd "$(dirname "$0")/../workflows"

if [ "$1" = "--all" ]; then
    # Import all workflows
    workflows=(
        "orchestrator.json"
        "ingestion.json"
        "rag_graph.json"
        "rag_classic.json"
        "rag_tabular.json"
        "enrichment.json"
        "monitor.json"
        "orchestrator_TestCopy.json"
        "ingestion_TestCopy.json"
    )
elif [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 --all                    # Import all workflows"
    echo "  $0 workflow1.json ...       # Import specific workflows"
    echo ""
    echo "Available workflows:"
    ls -1 *.json 2>/dev/null || echo "  No workflows found"
    exit 1
else
    workflows=("$@")
fi

# Import workflows
success_count=0
total_count=${#workflows[@]}

for workflow in "${workflows[@]}"; do
    if [ -f "$workflow" ]; then
        if import_workflow "$workflow"; then
            ((success_count++))
        fi
    else
        echo -e "${RED}✗ File not found: $workflow${NC}"
    fi
done

echo ""
echo "============================================================"
echo -e "Import completed: ${GREEN}$success_count${NC}/$total_count workflows imported"
echo "============================================================"

# Exit with error if not all succeeded
[ $success_count -eq $total_count ] && exit 0 || exit 1
