#!/bin/bash

echo "============================================================"
echo "Creating TestCopy workflows with Chat Trigger"
echo "============================================================"

create_testcopy() {
    local workflow_name="$1"
    local source_file=".github/workflows/${workflow_name}"
    local target_file="workflows/${workflow_name,,}_TestCopy.json"
    
    echo ""
    echo "📝 Processing: $workflow_name"
    
    if [ ! -f "$source_file" ]; then
        echo "✗ Source file not found: $source_file"
        return 1
    fi
    
    # Read and modify the workflow
    cat "$source_file" | \
        sed '0,/"name":/s/"name": *"\([^"]*\)"/"name": "\1 _TestCopy"/' | \
        sed 's/"type": *"n8n-nodes-base\.webhook"/"type": "@n8n\/n8n-nodes-langchain.chatTrigger"/' | \
        sed '/"type": *"@n8n\/n8n-nodes-langchain\.chatTrigger"/,/"position": *\[/{ 
            s/"typeVersion": *[0-9.]*/"typeVersion": 1.0/
            s/"name": *"[^"]*"/"name": "Chat Trigger"/
        }' > "$target_file"
    
    echo "✓ Replaced webhook with Chat Trigger"
    echo "✓ Created: $(basename "$target_file")"
    return 0
}

# Create test copies
success_count=0
total=0

for workflow in "Orchestrator" "Ingestion"; do
    ((total++))
    if create_testcopy "$workflow"; then
        ((success_count++))
    fi
done

echo ""
echo "============================================================"
echo "✓ Successfully created $success_count/$total test copies"
echo "============================================================"

exit $((total - success_count))
