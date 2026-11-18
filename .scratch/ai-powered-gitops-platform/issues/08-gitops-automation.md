# 08: GitOps Automation - Jenkins to ArgoCD Integration

**Status:** 🟡 READY TO START

**Objective:** Automate the GitOps workflow by having Jenkins update the GitOps repository, triggering ArgoCD to deploy changes automatically.

**Scope:**
- Configure Jenkins to push to GitOps repository
- Update Helm chart values in pipeline
- Commit and push changes to GitOps repo
- Configure ArgoCD to auto-sync
- Verify end-to-end deployment
- Document GitOps automation workflow

**Acceptance Criteria:**
- [ ] Jenkins can push to GitOps repository
- [ ] Jenkins updates Helm chart values in pipeline
- [ ] Jenkins commits changes to GitOps repo
- [ ] ArgoCD detects GitOps repository changes
- [ ] ArgoCD auto-syncs changes
- [ ] End-to-end deployment is successful
- [ ] Deployment status is visible in ArgoCD
- [ ] GitOps automation is documented

**Dependencies:**
- 05 (Harbor Integration) - Jenkins must push images to Harbor
- 07 (Helm Charts) - Helm charts must exist in GitOps repo

**Deliverables:**
- `platform-core/config/jenkins/Jenkinsfile-gitops` - GitOps pipeline stages
- `platform-core/scripts/setup-gitops-credentials.sh` - GitOps credentials setup
- `platform-core/docs/gitops/automation.md` - Automation guide
- `platform-core/docs/gitops/workflow.md` - Workflow documentation
- `platform-core/docs/gitops/troubleshooting.md` - Troubleshooting guide

**Implementation Details:**

**Pipeline Stages:**
1. Build application
2. Run security scans (Trivy, Syft, Cosign)
3. Push image to Harbor
4. Update GitOps repository (update image tag in values.yaml)
5. Commit and push to GitOps repo
6. ArgoCD auto-syncs
7. Verify deployment

**GitOps Repository Updates:**
- Update image tag in values.yaml
- Update chart version if needed
- Commit with structured message
- Push to main branch

**ArgoCD Configuration:**
- Auto-sync enabled
- Sync policy: automatic
- Prune resources enabled
- Self-heal enabled

**Authentication:**
- Jenkins SSH key for GitOps repo
- GitOps repo credentials in Jenkins
- Webhook from GitHub to Jenkins (already configured)

**Validation Steps:**
1. Set up GitOps repository credentials in Jenkins
2. Update Jenkinsfile to include GitOps stages
3. Configure ArgoCD Application for auto-sync
4. Trigger pipeline with code change
5. Verify image is pushed to Harbor
6. Verify GitOps repo is updated with new image tag
7. Verify ArgoCD detects change
8. Verify ArgoCD syncs deployment
9. Verify application is updated in cluster
10. Check ArgoCD UI for sync status

**Definition of Done:**
- Jenkins can update GitOps repository
- ArgoCD auto-syncs on GitOps changes
- End-to-end deployment works automatically
- GitOps workflow is documented
- Developer can push code and see automatic deployment
- Manual intervention is not required for deployments
