# 14: Ollama Foundation - AI Model Hosting

**Status:** 🟡 READY TO START

**Objective:** Install Ollama to host the Llama 3.1 8B model, providing the AI inference engine for the platform's AI Ops service.

**Scope:**
- Install Ollama in Kind cluster
- Pull and configure Llama 3.1 8B model
- Set up Ollama API endpoint
- Configure persistent storage for models
- Test model inference
- Document Ollama setup

**Acceptance Criteria:**
- [ ] Ollama is deployed to Kind cluster
- [ ] Llama 3.1 8B model is downloaded
- [ ] Ollama API is accessible
- [ ] Model inference works via API
- [ ] Persistent storage is configured for models
- [ ] Model loading time is acceptable
- [ ] API response time is acceptable
- [ ] Ollama setup is documented

**Dependencies:**
- 01 (Foundation - Kind Cluster) - Cluster must be running

**Deliverables:**
- `platform-core/config/ollama/values.yaml` - Helm values for Ollama
- `platform-core/config/ollama/model-config.yaml` - Model configuration
- `platform-core/scripts/install-ollama.sh` - Installation script
- `platform-core/scripts/pull-model.sh` - Model download script
- `platform-core/docs/ollama/installation.md` - Installation guide
- `platform-core/docs/ollama/api-usage.md` - API usage guide
- `platform-core/docs/ollama/model-management.md` - Model management guide

**Implementation Details:**

**Ollama Configuration:**
- Namespace: `ai-ops`
- Storage: PVC with 50Gi for models
- Service: ClusterIP
- Model: llama3.1:8b
- GPU: Not available in Kind (CPU inference)

**Model Configuration:**
- Llama 3.1 8B parameters
- Context window: 128k tokens
- Quantization: Q4_K_M for efficiency

**API Endpoints:**
- POST /api/generate - Text generation
- POST /api/chat - Chat completions
- GET /api/tags - List models

**Validation Steps:**
1. Run `./platform-core/scripts/install-ollama.sh`
2. Verify Ollama pods: `kubectl get pods -n ai-ops`
3. Run `./platform-core/scripts/pull-model.sh`
4. Verify model is loaded: `kubectl exec -n ai-ops <pod> -- ollama list`
5. Test model inference: `kubectl exec -n ai-ops <pod> -- ollama run llama3.1 "test"`
6. Port-forward to test API: `kubectl port-forward -n ai-ops svc/ollama 11434:11434`
7. Test API with curl: `curl http://localhost:11434/api/generate -d '{"model":"llama3.1","prompt":"test"}'`
8. Check model storage usage

**Definition of Done:**
- Ollama is deployed and running
- Llama 3.1 8B model is loaded
- API is accessible and functional
- Model inference works correctly
- Setup is documented
- Developer can interact with model via API
