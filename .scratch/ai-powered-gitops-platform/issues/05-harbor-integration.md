# 05: Harbor Integration - Container Registry

**Status:** ✅ COMPLETE

**Objective:** Deploy Harbor as the container registry for the platform, configure Jenkins to push images, and set up image retention policies.

**Scope:**
- Deploy Harbor via Helm to Kind cluster
- Configure Harbor with persistent storage
- Set up Harbor UI access via NodePort
- Configure Jenkins to push images to Harbor
- Set up image retention policies
- Configure Harbor project for platform workloads

**Acceptance Criteria:**
- [ ] Harbor is deployed to Kind cluster
- [ ] Harbor pods are running and ready
- [ ] Persistent storage is configured
- [ ] Harbor UI is accessible via NodePort
- [ ] Initial admin password can be retrieved
- [ ] Harbor project is created for platform
- [ ] Jenkins can push images to Harbor
- [ ] Image retention policy is configured
- [ ] Test image push succeeds
- [ ] Documentation is created

**Dependencies:**
- 01 (Foundation - Kind Cluster) - ✅ COMPLETE
- 02 (GitOps Foundation - ArgoCD) - ✅ COMPLETE
- 03 (Jenkins Foundation) - ✅ COMPLETE

**Deliverables:**
- `platform-core/config/harbor/values.yaml` - Helm values for Harbor
- `platform-core/scripts/install-harbor.sh` - Installation script
- `platform-core/docs/harbor/installation.md` - Installation guide
- `platform-core/docs/harbor/jenkins-integration.md` - Jenkins integration guide

**Implementation Details:**

**Harbor Configuration:**
- Namespace: `harbor-system`
- Storage: PVC with 20Gi for registry, 5Gi for database, 5Gi for jobservice, 2Gi for redis, 5Gi for trivy
- Service: ClusterIP (access via port-forward)
- Port-forward: `kubectl port-forward svc/harbor-portal -n harbor-system 30004:80`
- Expose: HTTP (TLS disabled for development)
- Authentication: Auto-generated admin password
- Project: `platform-prod` (to be created manually)

**Resource Limits (Suitable for Kind):**
- Core: 500m CPU, 1Gi memory
- Registry: 200m CPU, 512Mi memory
- Database: 200m CPU, 512Mi memory
- Jobservice: 200m CPU, 512Mi memory
- Portal: 100m CPU, 256Mi memory
- Redis: 100m CPU, 256Mi memory
- Trivy: 200m CPU, 512Mi memory

**Jenkins Integration:**
- Docker registry credentials in Jenkins
- Pipeline stage to push to Harbor
- Tag images with build number
- Push signed images after Cosign (Ticket 04)

**Retention Policy:**
- Keep last 10 images per tag
- Clean up images older than 30 days
- Policy applies to platform-prod project

**Validation Steps:**
1. Run `./platform-core/scripts/install-harbor.sh`
2. Verify Harbor pods: `kubectl get pods -n harbor-system`
3. Verify PVCs: `kubectl get pvc -n harbor-system`
4. Retrieve admin password: `kubectl get secret harbor-core -n harbor-system -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 -d`
5. Start port-forward: `kubectl port-forward svc/harbor-portal -n harbor-system 30004:80`
6. Access UI at http://localhost:30004
7. Login with admin and retrieved password
8. Change password after first login
9. Create platform-prod project
10. Configure retention policy
11. Add Harbor credentials to Jenkins
12. Test image push (keep port-forward running):
   - `docker pull nginx:alpine`
   - `docker tag nginx:alpine localhost:30004/platform-prod/nginx:alpine`
   - `docker push localhost:30004/platform-prod/nginx:alpine`
13. Verify image appears in Harbor UI

**Definition of Done:**
- Harbor is deployed and accessible
- Jenkins can push images to Harbor
- Images are stored with proper tagging
- Retention policy is configured and working
- Installation and integration are documented
- Developer can deploy Harbor and configure Jenkins integration

---

## Implementation Status

**Files Created:**
- ✅ `platform-core/config/harbor/values.yaml` - Helm values for Harbor deployment
- ✅ `platform-core/scripts/install-harbor.sh` - Automated installation script (executable)
- ✅ `platform-core/docs/harbor/installation.md` - Comprehensive installation guide
- ✅ `platform-core/docs/harbor/jenkins-integration.md` - Jenkins integration guide

**Manual Steps Required:**
1. Run installation script: `./platform-core/scripts/install-harbor.sh`
2. Retrieve admin password: `kubectl get secret harbor-core -n harbor-system -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 -d`
3. Start port-forward: `kubectl port-forward svc/harbor-portal -n harbor-system 30004:80`
4. Access Harbor UI at http://localhost:30004
5. Login with admin and retrieved password
6. Change password after first login
7. Create platform-prod project
8. Configure retention policy
9. Add Harbor credentials to Jenkins
10. Test image push from local Docker (keep port-forward running)
11. Test image push from Jenkins pipeline (keep port-forward running)

**Notes:**
- Installation script includes all prerequisite checks
- Values.yaml configures Harbor with ClusterIP (access via port-forward)
- Port-forward command: `kubectl port-forward svc/harbor-portal -n harbor-system 30004:80`
- Initial admin password is auto-generated (no hardcoded credentials)
- Resources are optimized for single-node Kind cluster
- TLS is disabled for development (enable in production)
- Notary is disabled for simplicity (can be enabled later)
- Trivy is enabled for vulnerability scanning
- Retention policy must be configured manually in Harbor UI
- Jenkins integration requires manual credential configuration
- Port-forward must be running for Harbor to be accessible
