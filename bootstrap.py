import os

structure = {
    'workflows/raw': [],
    'workflows/fixed': [],
    'workflows/final': [],
    'config': ['n8n-env-vars.yaml', 'postgres-schema.sql'],
    'scripts': ['download_datasets.py', 'verify_envs.py'],
    'prompts': [
        'agent1-setup.md',
        'agent2-import.md',
        'agent3-fix.md',
        'agent4-eval.md',
        'agent5-orchestrator.md'
    ],
    'datasets': [],
    'logs': [],
    'error-logs': [],
    'evaluations': ['evaluation_framework.py']
}

for folder, files in structure.items():
    os.makedirs(folder, exist_ok=True)
    for file in files:
        open(os.path.join(folder, file), 'a').close()

print("Structure créée !")
