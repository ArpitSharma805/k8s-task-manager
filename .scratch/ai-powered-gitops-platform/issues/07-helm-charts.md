# 07: Helm Charts - Platform Application Packaging

**Status:** 🟡 READY TO START

**Objective:** Create Helm charts for platform components and organize values files for different environments.

**Scope:**
- Create Helm chart for sample application
- Organize values files (dev, staging, prod)
- Validate Helm chart templates
- Integrate Helm charts with ArgoCD
- Document Helm chart structure and usage

**Acceptance Criteria:**
- [ ] Helm chart is created for sample application
- [ ] Values files are organized by environment
- [ ] Helm chart templates are valid
- [ ] Helm chart can be installed successfully
- [ ] ArgoCD can deploy Helm chart
- [ ] Values override mechanism works
- [ ] Helm chart is documented
- [ ] Chart follows best practices

**Dependencies:**
- 06 (Sample Application) - Application must exist before charting

**Deliverables:**
- `platform-core/charts/sample-app/Chart.yaml` - Chart metadata
- `platform-core/charts/sample-app/values.yaml` - Default values
- `platform-core/charts/sample-app/values-dev.yaml` - Dev environment values
- `platform-core/charts/sample-app/values-prod.yaml` - Prod environment values
- `platform-core/charts/sample-app/templates/*.yaml` - Kubernetes templates
- `platform-core/charts/sample-app/.helmignore` - Helm ignore file
- `platform-core/docs/helm/chart-structure.md` - Chart structure guide
- `platform-core/docs/helm/values-organization.md` - Values organization guide

**Implementation Details:**

**Chart Structure:**
- Chart.yaml with version and dependencies
- values.yaml with default configuration
- values-*.yaml for environment-specific overrides
- templates/ directory with Kubernetes manifests
- templates/_helpers.tpl for template helpers
- NOTES.txt for post-install instructions

**Templates:**
- deployment.yaml
- service.yaml
- configmap.yaml
- secret.yaml (if needed)
- ingress.yaml (optional)
- hpa.yaml (optional)
- serviceaccount.yaml

**Values Organization:**
- Global values (image registry, pull policy)
- Environment-specific values (replicas, resources)
- Feature flags
- Configuration overrides

**ArgoCD Integration:**
- Add Helm chart to GitOps repository
- Create ArgoCD Application for Helm chart
- Configure value files in Application manifest
- Enable auto-sync

**Validation Steps:**
1. Lint Helm chart: `helm lint ./charts/sample-app`
2. Template chart: `helm template sample-app ./charts/sample-app`
3. Install chart: `helm install sample-app ./charts/sample-app`
4. Install with values override: `helm install sample-app ./charts/sample-app -f values-dev.yaml`
5. Verify deployment: `kubectl get all`
6. Upgrade chart: `helm upgrade sample-app ./charts/sample-app`
7. Test rollback: `helm rollback sample-app`
8. Add to GitOps repo
9. Create ArgoCD Application
10. Verify ArgoCD deploys chart

**Definition of Done:**
- Helm chart is created and valid
- Values files are organized by environment
- Chart can be installed and upgraded
- ArgoCD can deploy the chart
- Chart follows Helm best practices
- Chart is documented
- Developer can create and deploy Helm charts
