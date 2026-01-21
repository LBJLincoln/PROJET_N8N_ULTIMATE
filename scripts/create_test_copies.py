#!/usr/bin/env python3
"""
Create TestCopy workflows with Chat Trigger replacing Webhook nodes
"""
import json
import sys
from pathlib import Path

def replace_webhook_with_chat_trigger(workflow_data, workflow_name):
    """Replace webhook node with Chat Trigger node"""

    # Update workflow name
    original_name = workflow_data.get("name", "")
    workflow_data["name"] = f"{original_name} _TestCopy"

    # Find and replace webhook nodes
    webhook_replaced = False
    for node in workflow_data.get("nodes", []):
        if node.get("type") == "n8n-nodes-base.webhook":
            # Replace with Chat Trigger
            node["type"] = "@n8n/n8n-nodes-langchain.chatTrigger"
            node["typeVersion"] = 1.0
            node["name"] = "Chat Trigger"

            # Update parameters for Chat Trigger
            node["parameters"] = {
                "options": {}
            }

            webhook_replaced = True
            print(f"✓ Replaced webhook node '{node.get('name', 'Unknown')}' with Chat Trigger")

    if not webhook_replaced:
        print(f"⚠ Warning: No webhook node found in {workflow_name}")

    return workflow_data

def create_test_copy(source_path, target_path):
    """Create a test copy of a workflow"""
    try:
        with open(source_path, 'r', encoding='utf-8') as f:
            workflow_data = json.load(f)

        # Replace webhook with chat trigger
        modified_workflow = replace_webhook_with_chat_trigger(
            workflow_data,
            source_path.stem
        )

        # Save to target path
        with open(target_path, 'w', encoding='utf-8') as f:
            json.dump(modified_workflow, f, indent=2, ensure_ascii=False)

        print(f"✓ Created: {target_path}")
        return True

    except json.JSONDecodeError as e:
        print(f"✗ JSON Error in {source_path}: {e}")
        return False
    except Exception as e:
        print(f"✗ Error processing {source_path}: {e}")
        return False

def main():
    project_root = Path(__file__).parent.parent
    workflows_dir = project_root / "workflows"

    # Workflows to create test copies for
    workflows_to_copy = ["orchestrator", "ingestion"]

    print("=" * 60)
    print("Creating TestCopy workflows with Chat Trigger")
    print("=" * 60)

    success_count = 0
    for workflow_name in workflows_to_copy:
        source_file = workflows_dir / f"{workflow_name}.json"
        target_file = workflows_dir / f"{workflow_name}_TestCopy.json"

        print(f"\n📝 Processing: {workflow_name}")
        if create_test_copy(source_file, target_file):
            success_count += 1

    print("\n" + "=" * 60)
    print(f"✓ Successfully created {success_count}/{len(workflows_to_copy)} test copies")
    print("=" * 60)

    return 0 if success_count == len(workflows_to_copy) else 1

if __name__ == "__main__":
    sys.exit(main())
