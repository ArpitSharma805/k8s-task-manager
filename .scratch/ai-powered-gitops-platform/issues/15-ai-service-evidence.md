# 15: AI Ops Service - Evidence Collection

**Status:** 🟡 READY TO START

**Objective:** Build a FastAPI service that collects evidence from the platform (Jenkins, ArgoCD, Prometheus, Harbor) and prepares it for AI analysis.

**Scope:**
- Create FastAPI application
- Implement evidence collection from Jenkins
- Implement evidence collection from ArgoCD
- Implement evidence collection from Prometheus
- Implement evidence collection from Harbor
- Normalize evidence data
- Expose API endpoints for evidence
- Document evidence schema

**Acceptance Criteria:**
- [ ] FastAPI service is created
- [ ] Service collects Jenkins build evidence
- [ ] Service collects ArgoCD sync evidence
- [ ] Service collects Prometheus metrics evidence
- [ ] Service collects Harbor image evidence
- [ ] Evidence is normalized to common schema
- [ ] API endpoints return evidence
- [ ] Evidence schema is documented

**Dependencies:**
- 03 (Jenkins Foundation) - Jenkins must be running
- 02 (ArgoCD Foundation) - ArgoCD must be running
- 10 (Prometheus Operator) - Prometheus must be running
- 05 (Harbor Integration) - Harbor must be running

**Deliverables:**
- `platform-core/ai-ops-service/app/main.py` - FastAPI application
- `platform-core/ai-ops-service/app/models/evidence.py` - Evidence data models
- `platform-core/ai-ops-service/app/collectors/jenkins.py` - Jenkins evidence collector
- `platform-core/ai-ops-service/app/collectors/argocd.py` - ArgoCD evidence collector
- `platform-core/ai-ops-service/app/collectors/prometheus.py` - Prometheus evidence collector
- `platform-core/ai-ops-service/app/collectors/harbor.py` - Harbor evidence collector
- `platform-core/ai-ops-service/Dockerfile` - Container definition
- `platform-core/docs/ai-ops/evidence-schema.md` - Evidence schema documentation
- `platform-core/docs/ai-ops/api-endpoints.md` - API endpoints documentation

**Implementation Details:**

**Evidence Schema:**
```json
{
  "timestamp": "ISO8601",
  "source": "jenkins|argocd|prometheus|harbor",
  "type": "build|sync|metric|image",
  "data": { ... }
}
```

**API Endpoints:**
- GET /api/evidence/jenkins - Jenkins evidence
- GET /api/evidence/argocd - ArgoCD evidence
- GET /api/evidence/prometheus - Prometheus evidence
- GET /api/evidence/harbor - Harbor evidence
- GET /api/evidence/all - All evidence combined

**Evidence Collectors:**
- Jenkins: Build status, duration, artifacts
- ArgoCD: Sync status, health, resources
- Prometheus: Metrics, alerts, targets
- Harbor: Image vulnerabilities, signatures

**Validation Steps:**
1. Create FastAPI application structure
2. Implement evidence collectors
3. Test each collector individually
4. Run service locally: `uvicorn app.main:app --reload`
5. Test API endpoints with curl
6. Verify evidence schema is consistent
7. Build Docker image
8. Deploy to cluster
9. Test API from cluster

**Definition of Done:**
- FastAPI service is created
- Evidence collectors work for all sources
- Evidence is normalized to common schema
- API endpoints return evidence
- Evidence schema is documented
- Service can be deployed to cluster
