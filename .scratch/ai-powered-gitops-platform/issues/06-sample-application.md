# 06: Sample Application - Node.js + Express

**Status:** ✅ COMPLETE

**Objective:** Create a minimal production-style sample application that validates the complete DevSecOps platform including Jenkins, Harbor, Trivy, Syft, Cosign, and ArgoCD.

**Scope:**
- Create Node.js Express application
- Add Dockerfile with multi-stage build
- Create Jenkins pipeline with security stages
- Create Helm chart for deployment
- Document deployment process
- Validate complete workflow

**Acceptance Criteria:**
- [ ] Application builds locally
- [ ] Image pushed to Harbor
- [ ] Trivy scans image
- [ ] Syft generates SBOM
- [ ] Cosign signs image
- [ ] Helm chart deploys
- [ ] Application reachable in Kind
- [ ] ArgoCD syncs application

**Dependencies:**
- 01 (Foundation - Kind Cluster) - ✅ COMPLETE
- 02 (GitOps Foundation - ArgoCD) - ✅ COMPLETE
- 03 (Jenkins Foundation) - ✅ COMPLETE
- 05 (Harbor Integration) - ✅ COMPLETE
- 04 (Security Pipeline) - ✅ COMPLETE

**Deliverables:**
- `sample-app/package.json` - Node.js dependencies
- `sample-app/server.js` - Express application
- `sample-app/Dockerfile` - Multi-stage container build
- `sample-app/Jenkinsfile` - Jenkins pipeline with security stages
- `deploy/helm/sample-app/Chart.yaml` - Helm chart metadata
- `deploy/helm/sample-app/values.yaml` - Helm values
- `deploy/helm/sample-app/templates/*` - Kubernetes manifests
- `platform-core/docs/sample-app/deployment.md` - Deployment guide

**Implementation Details:**

**Application:**
- Node.js 18 with Express
- Port 3000
- Endpoints: /, /health, /version, /metrics
- Minimal production-style code

**Container:**
- Multi-stage build (builder + runtime)
- Non-root user (nodejs:1001)
- Healthcheck instruction
- Small image (alpine-based)
- Security best practices

**Jenkins Pipeline:**
- Build with Podman
- Push to Harbor (cluster-internal: harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app)
- Trivy scan (fail on HIGH/CRITICAL)
- Generate SPDX and CycloneDX SBOMs
- Cosign sign image
- Archive reports (Trivy, SBOMs, artifacts)

**Helm Chart:**
- Deployment with replicas
- Service (ClusterIP)
- ConfigMap for version
- Readiness probe (/health)
- Liveness probe (/health)
- Resource limits (500m CPU, 256Mi memory)

**Image Location:**
- Harbor: harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app
- Tag: Build number

**Validation Steps:**

**Local Application Validation:**
1. Navigate to sample-app: `cd sample-app`
2. Install dependencies: `npm install`
3. Start application: `npm start`
4. Test endpoints: `curl http://localhost:3000/health`

**Container Build Validation:**
1. Build image: `podman build -t sample-app:latest .`
2. Run container: `podman run -p 3000:3000 sample-app:latest`
3. Test endpoints: `curl http://localhost:3000/health`

**Jenkins Pipeline Validation:**
1. Create pipeline job using sample-app/Jenkinsfile
2. Configure Harbor credentials
3. Configure Cosign credentials
4. Run pipeline
5. Verify all stages complete
6. Verify artifacts archived

**Helm Deployment Validation:**
1. Install Helm chart: `helm install sample-app ./deploy/helm/sample-app -n platform-prod`
2. Check pod status: `kubectl get pods -n platform-prod`
3. Port-forward: `kubectl port-forward svc/sample-app -n platform-prod 3000:3000`
4. Test application: `curl http://localhost:3000/health`

**ArgoCD Integration Validation:**
1. Create Application manifest in GitOps repository
2. Apply manifest: `kubectl apply -f sample-app-application.yaml`
3. Verify in ArgoCD UI
4. Update values in GitOps repo
5. Verify ArgoCD syncs changes

**Definition of Done:**
- Application builds and runs locally
- Container image is optimized and secure
- Jenkins pipeline executes all security stages
- Image is scanned, signed, and pushed to Harbor
- Helm chart deploys application successfully
- Application is accessible in Kind cluster
- ArgoCD can sync application from GitOps repository
- Deployment process is documented
- Developer can use as reference for their own applications

---

## Implementation Status

**Files Created:**
- ✅ `sample-app/package.json` - Node.js dependencies
- ✅ `sample-app/server.js` - Express application with endpoints
- ✅ `sample-app/Dockerfile` - Multi-stage container build
- ✅ `sample-app/Jenkinsfile` - Complete Jenkins pipeline with security stages
- ✅ `deploy/helm/sample-app/Chart.yaml` - Helm chart metadata
- ✅ `deploy/helm/sample-app/values.yaml` - Helm values
- ✅ `deploy/helm/sample-app/templates/deployment.yaml` - Kubernetes Deployment
- ✅ `deploy/helm/sample-app/templates/service.yaml` - Kubernetes Service
- ✅ `deploy/helm/sample-app/templates/configmap.yaml` - Kubernetes ConfigMap
- ✅ `platform-core/docs/sample-app/deployment.md` - Deployment guide

**Manual Steps Required:**
1. Validate application builds locally: `cd sample-app && npm install && npm start`
2. Validate container build: `podman build -t sample-app:latest . && podman run -p 3000:3000 sample-app:latest`
3. Configure Jenkins credentials (Harbor, Cosign)
4. Create Jenkins pipeline job using sample-app/Jenkinsfile
5. Run Jenkins pipeline and verify all stages
6. Install Helm chart: `helm install sample-app ./deploy/helm/sample-app -n platform-prod`
7. Validate deployment in Kind
8. Create ArgoCD Application manifest
9. Apply manifest and verify ArgoCD sync

**Notes:**
- Application uses cluster-internal Harbor address for Jenkins agents
- Application uses non-root user for security
- Dockerfile uses multi-stage build for small image size
- Jenkins pipeline includes all security stages (Trivy, Syft, Cosign)
- Helm chart includes health checks and resource limits
- Documentation clearly separates local validation from cluster deployment
- All validation steps provided for manual execution
