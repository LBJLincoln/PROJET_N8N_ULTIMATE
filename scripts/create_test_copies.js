#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const workflowsDir = path.join(__dirname, '..', 'workflows');

function readWorkflowFile(filePath) {
    const content = fs.readFileSync(filePath, 'utf8');
    try {
        return JSON.parse(content);
    } catch (e) {
        console.error(`Error parsing ${path.basename(filePath)}: ${e.message}`);
        return null;
    }
}

function createTestCopy(workflowName) {
    const sourcePath = path.join(workflowsDir, `${workflowName}.json`);
    const targetPath = path.join(workflowsDir, `${workflowName}_TestCopy.json`);

    console.log(`\n📝 Processing: ${workflowName}`);

    const workflow = readWorkflowFile(sourcePath);
    if (!workflow) {
        console.log(`✗ Failed to read workflow`);
        return false;
    }

    // Update workflow name
    workflow.name = `${workflow.name} _TestCopy`;

    // Find and replace webhook nodes
    let webhookReplaced = false;
    for (const node of (workflow.nodes || [])) {
        if (node.type === 'n8n-nodes-base.webhook') {
            node.type = '@n8n/n8n-nodes-langchain.chatTrigger';
            node.typeVersion = 1.0;
            node.name = 'Chat Trigger';
            node.parameters = { options: {} };
            webhookReplaced = true;
            console.log(`✓ Replaced webhook with Chat Trigger`);
        }
    }

    if (!webhookReplaced) {
        console.log(`⚠  Warning: No webhook node found`);
    }

    // Save
    try {
        fs.writeFileSync(targetPath, JSON.stringify(workflow, null, 2));
        console.log(`✓ Created: ${path.basename(targetPath)}`);
        return true;
    } catch (e) {
        console.log(`✗ Failed to save: ${e.message}`);
        return false;
    }
}

console.log('='.repeat(60));
console.log('Creating TestCopy workflows with Chat Trigger');
console.log('='.repeat(60));

const workflows = ['orchestrator', 'ingestion'];
let successCount = 0;

for (const wf of workflows) {
    if (createTestCopy(wf)) {
        successCount++;
    }
}

console.log('\n' + '='.repeat(60));
console.log(`✓ Successfully created ${successCount}/${workflows.length} test copies`);
console.log('='.repeat(60));

process.exit(successCount === workflows.length ? 0 : 1);
