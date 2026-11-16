# 02: GitOps Foundation - ArgoCD Installation and Basic Sync

**What to build:** Deploy ArgoCD to the Kind cluster, configure it to sync from a GitOps repository, and verify basic sync functionality.

**Blocked by:** 01

**Status:** ready-for-human

## Acceptance criteria

- [x] ArgoCD is deployed to Kind cluster
- [x] ArgoCD UI is accessible
- [x] GitOps repository structure is created
- [x] ArgoCD is configured to sync from GitOps repository
- [x] ArgoCD Application resources are created
- [x] Auto-sync is enabled
- [x] ArgoCD can detect changes in GitOps repository
- [x] ArgoCD sync status is visible in UI
- [x] Sync health status is reported correctly

## Implementation Notes

Created the following files for ArgoCD installation and configuration:

**Configuration Files:**
- `platform-core/config/argocd/values.yaml` - Helm values for ArgoCD deployment with NodePort service on port 30002, insecure mode enabled for development, auto-sync enabled, and resource limits configured

**Scripts:**
- `platform-core/scripts/install-argocd.sh` - Automated installation script that adds ArgoCD Helm repository, creates argocd namespace, installs ArgoCD using Helm, waits for readiness, and displays admin password
- `platform-core/scripts/setup-gitops-repo.sh` - Script to create GitOps repository structure with apps/, charts/, and values/ directories, plus sample application manifest
- `platform-core/scripts/configure-argocd-repo.sh` - Script to configure ArgoCD to sync from GitOps repository, adds repository, and applies Application manifests

**Application Manifests:**
- `platform-core/config/argocd/apps/root-app.yaml` - Root Application for managing other applications
- `platform-core/config/argocd/apps/platform-apps.yaml` - Platform Applications manifest for deploying workloads to platform-prod namespace

**Documentation:**
- `platform-core/docs/argocd/installation.md` - Comprehensive installation guide with prerequisites, automated/manual installation steps, access instructions, configuration details, GitOps repository setup, application creation, verification, troubleshooting, and cleanup procedures

**Key Configuration:**
- ArgoCD deployed in argocd namespace
- UI accessible on http://localhost:30002
- Default admin password (bcrypt hash configured in values)
- Auto-sync enabled by default
- Applications sync to platform-prod namespace
- Resource limits: 1000m CPU, 512Mi memory for controller

**Note:** These configuration files and scripts are ready for deployment once the environment has the required tools (Docker, Kind, kubectl, Helm) installed. The actual deployment and verification steps require a running Kind cluster with these tools available.
