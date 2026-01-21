# Guide d'Import des Workflows n8n

## Vue d'ensemble

Ce guide explique comment importer les 7 workflows RAG dans votre instance n8n cloud.

**Instance n8n**: `https://amoret.app.n8n.cloud`

## Fichiers de Workflows

### Workflows de Production
1. **orchestrator.json** (11K) - Orchestrator V6.0 - Master Router
2. **ingestion.json** (16K) - Document Ingestion Pipeline
3. **rag_graph.json** (13K) - Graph RAG Implementation
4. **rag_classic.json** (9.8K) - Classic RAG Workflow
5. **rag_tabular.json** (13K) - RAG Quantitatif/Tabular
6. **enrichment.json** (17K) - Enrichment Pipeline
7. **monitor.json** (13K) - Feedback & Monitoring V3.0

### Workflows de Test (avec Chat Trigger)
- **orchestrator_TestCopy.json** - Version test de l'orchestrator (webhook → Chat Trigger)
- **ingestion_TestCopy.json** - Version test de l'ingestion (webhook → Chat Trigger)

## Méthode 1: Import via Script (Recommandé)

### Prérequis
- Accès réseau à votre instance n8n
- API key n8n (Settings → API dans n8n)
- Bash shell

### Étapes

1. **Obtenir votre API key n8n**
   ```bash
   # Ouvrir dans le navigateur:
   # https://amoret.app.n8n.cloud/settings/api
   ```

2. **Configurer l'environnement**
   ```bash
   export N8N_API_KEY="votre-api-key-ici"
   export N8N_API_URL="https://amoret.app.n8n.cloud"
   ```

3. **Importer tous les workflows**
   ```bash
   chmod +x scripts/import_to_n8n.sh
   ./scripts/import_to_n8n.sh --all
   ```

4. **Ou importer des workflows spécifiques**
   ```bash
   ./scripts/import_to_n8n.sh orchestrator_TestCopy.json ingestion_TestCopy.json
   ```

### Exemple de sortie
```
============================================================
n8n Workflow Import Script
============================================================
Instance: https://amoret.app.n8n.cloud

📝 Importing orchestrator... ✓ Success (ID: abc123)
📝 Importing ingestion... ✓ Success (ID: def456)
...
============================================================
Import completed: 9/9 workflows imported
============================================================
```

## Méthode 2: Import Manuel via Interface n8n

### Étapes

1. **Se connecter à n8n**
   - Ouvrir https://amoret.app.n8n.cloud

2. **Pour chaque workflow:**
   - Cliquer sur "Add workflow" → "Import from File"
   - Sélectionner le fichier JSON (ex: `workflows/orchestrator.json`)
   - Cliquer sur "Import"
   - Vérifier les credentials (PostgreSQL, API keys, etc.)
   - Activer le workflow

3. **Configurer les credentials**
   Les workflows nécessitent les credentials suivants:
   - **Postgres Production** (PostgreSQL database)
   - **OpenAI API Key** (pour les appels LLM)
   - **MongoDB API Key** (pour le monitoring)
   - **Slack Webhook** (pour les notifications)

## Méthode 3: Import via MCP (Avancé)

Si vous avez configuré le serveur MCP n8n localement:

1. **Vérifier la configuration MCP**
   ```bash
   cat .mcp.json
   ```

2. **Utiliser les skills n8n**
   Les skills n8n-mcp sont installés dans `~/.claude/skills/`:
   - n8n-mcp-tools-expert
   - n8n-workflow-patterns
   - n8n-node-configuration
   - etc.

3. **Importer via Claude Code (si MCP configuré)**
   ```
   "Import the workflows from workflows/ directory to n8n"
   ```

## Test des Workflows

### Test avec Chat Trigger (Recommandé pour débuter)

1. **Importer les versions TestCopy**
   ```bash
   ./scripts/import_to_n8n.sh orchestrator_TestCopy.json ingestion_TestCopy.json
   ```

2. **Tester dans l'interface n8n**
   - Ouvrir le workflow *_TestCopy
   - Utiliser le Chat Trigger pour envoyer une requête test
   - Exemple: `"What is machine learning?"`

3. **Vérifier la sortie**
   - Chaque nœud devrait s'exécuter correctement
   - Vérifier les logs pour les erreurs

### Test avec Webhook (Production)

1. **Activer le workflow de production**
   - Activer orchestrator.json dans n8n

2. **Envoyer une requête test**
   ```bash
   curl -X POST "https://amoret.app.n8n.cloud/webhook/rag-v5-orchestrator" \
     -H "Content-Type: application/json" \
     -d '{
       "query": "What is machine learning?",
       "user_id": "test_user",
       "tenant_id": "test_tenant"
     }'
   ```

3. **Vérifier la réponse**

## Dépannage

### Erreur: "CONNECT tunnel failed, response 403"
- Vous êtes derrière un proxy/firewall qui bloque les requêtes HTTPS
- Solution: Utiliser l'import manuel via l'interface n8n

### Erreur: "Unauthorized" ou HTTP 401
- Votre API key est invalide ou expirée
- Solution: Regénérer une nouvelle API key dans n8n Settings → API

### Erreur: "Missing credentials"
- Les workflows référencent des credentials non configurés
- Solution: Créer les credentials requis dans n8n Settings → Credentials

### Workflow inactif après import
- Les workflows importés sont désactivés par défaut
- Solution: Activer manuellement chaque workflow dans l'interface n8n

## Structure du Projet

```
PROJET_N8N_ULTIMATE/
├── workflows/              # Workflows n8n
│   ├── orchestrator.json
│   ├── ingestion.json
│   ├── rag_graph.json
│   ├── rag_classic.json
│   ├── rag_tabular.json
│   ├── enrichment.json
│   ├── monitor.json
│   ├── orchestrator_TestCopy.json
│   └── ingestion_TestCopy.json
├── scripts/                # Scripts d'automatisation
│   ├── import_to_n8n.sh           # Script d'import principal
│   ├── create_test_copies.sh     # Créer versions TestCopy
│   └── download_datasets.py      # Télécharger datasets
├── .mcp.json               # Configuration MCP (gitignored)
└── IMPORT_GUIDE.md         # Ce fichier
```

## Prochaines Étapes

Après l'import réussi:

1. ✅ **Configurer les credentials** dans n8n
2. ✅ **Tester les workflows TestCopy** avec Chat Trigger
3. ✅ **Vérifier les connexions** entre workflows (orchestrator → ingestion → RAG)
4. ✅ **Activer les webhooks** de production
5. ✅ **Configurer le monitoring** (Slack notifications)

## Ressources

- [Documentation n8n](https://docs.n8n.io/)
- [n8n API Documentation](https://docs.n8n.io/api/)
- [n8n MCP Server](https://github.com/czlonkowski/n8n-mcp)
- [n8n Skills for Claude](https://github.com/czlonkowski/n8n-skills)

## Support

Pour toute question ou problème:
1. Vérifier les logs d'exécution dans n8n
2. Consulter `error-logs/agent2-*.txt` pour les erreurs d'import
3. Vérifier la configuration des credentials

---

**Note**: Les fichiers sensibles (.mcp.json, .env.n8n) sont exclus du versioning git pour des raisons de sécurité.
