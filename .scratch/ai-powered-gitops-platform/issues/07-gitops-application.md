# 07: GitOps Application Deployment

**Status:** 🟡 FILES READY - MANUAL STEPS REQUIRED

**Objective:** Implement a complete GitOps workflow using ArgoCD to deploy the sample application.

**Scope:**
- Create ArgoCD Application manifest
- Set up GitOps repository structure
- Configure environment-specific values
- Enable automatic sync and self-heal
- Document image update strategy
- Document validation workflow

**Acceptance Criteria:**
- [ ] ArgoCD application manifest created
- [ ] GitOps folder structure created
- [ ] Automatic sync configured
- [ ] Self-heal configured
- [ ] Deployment documentation written
- [ ] Validation procedure documented

**Dependencies:**
- 01 (Foundation - Kind Cluster) - ✅ COMPLETE
- 02 (GitOps Foundation - ArgoCD) - ✅ COMPLETE
- 03 (Jenkins Foundation) - ✅ COMPLETE
- 05 (Harbor Integration) - ✅ COMPLETE
- 04 (Security Pipeline) - ✅ COMPLETE
- 06 (Sample Application) - ✅ COMPLETE

**Deliverables:**
- `gitops/apps/sample-app/application.yaml` - ArgoCD Application manifest
- `gitops/apps/sample-app/kustomization.yaml` - Kustomization for apps
- `gitops/environments/dev/sample-app-values.yaml` - Environment values
- `gitops/environments/dev/kustomization.yaml` - Kustomization for environment
- `platform-core/docs/gitops/argocd-sample-app.md` - Deployment guide
- `platform-core/docs/gitops/image-update-strategy.md` - Image update strategy

**Implementation Details:**

**ArgoCD Application:**
- Uses Helm chart from deploy/helm/sample-app
- Deploys to namespace platform-prod
- Automatic sync enabled
- Self-heal enabled
- Prune enabled
- Source: GitOps repository
- TargetRevision: main

**GitOps Structure:**
```
gitops/
├── apps/
│   └── sample-app/
│       ├── application.yaml
│       └── kustomization.yaml
└── environments/
    └── dev/
        ├── sample-app-values.yaml
        └── kustomization.yaml
```

**Image Strategy:**
- Harbor location: harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app
- Support image tag updates
- Document immutable tags
- Document digest-based deployments
- Harbor integration guidance

**Validation Workflow:**
1. Commit Git change to GitOps repository
2. Push repository
3. ArgoCD detects change
4. ArgoCD syncs deployment
5. Verify application updated

**Validation Steps:**
1. Apply Application manifest: `kubectl apply -f gitops/apps/sample-app/kustomization.yaml`
2. Verify in ArgoCD UI
3. Update image tag in gitops/environments/dev/sample-app-values.yaml
4. Commit and push to GitOps repository
5. Verify ArgoCD syncs deployment
6. Verify application is updated in cluster

**Definition of Done:**
- ArgoCD application manifest created
- GitOps repository structure created
- Automatic sync configured
- Self-heal configured
- Deployment documentation written
- Validation procedure documented
- Developer can deploy application via GitOps

---

## Implementation Status

**Files Created:**
- ✅ `gitops/apps/sample-app/application.yaml` - ArgoCD Application manifest
- ✅ `gitops/apps/sample-app/kustomization.yaml` - Kustomization for apps
- ✅ `gitops/environments/dev/sample-app-values.yaml` - Environment values
- ✅ `gitops/environments/dev/kustomization.yaml` - Kustomization for environment
- ✅ `platform-core/docs/gitops/argocd-sample-app.md` - Deployment guide
- ✅ `platform-core/docs/gitops/image-update-strategy.md` - Image update strategy

**Manual Steps Required:**
1. Update GitOps repository URL in application.yaml
2. Apply Application manifest: `kubectl apply -f gitops/apps/sample-app/kustomization.yaml`
3. Verify in ArgoCD UI
4. Update image tag in gitops/environments/dev/sample-app-values.yaml
5. Commit and push to GitOps repository
6. Verify ArgoCD syncs deployment
7. Verify application is updated in cluster

**Notes:**
- Application uses cluster-internal Harbor address
- GitOps structure separates apps from environments
- Kustomization patches environment-specific values
- Automatic sync and self-heal enabled
- Prune enabled to remove old resources
- Image update strategy documented with best practices
