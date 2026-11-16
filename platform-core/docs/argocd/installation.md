# ArgoCD Installation Guide

This document describes the installation and configuration of ArgoCD for the AI-Powered GitOps Platform.

## Prerequisites

Before installing ArgoCD, ensure you have:
- Kind cluster running (see Kind cluster installation guide)
- kubectl installed and configured
- Helm installed

## Installation

### Automated Installation

Run the installation script:

```bash
cd platform-core
./scripts/install-argocd.sh
```

This script will:
1. Add the ArgoCD Helm repository
2. Create the argocd namespace
3. Install ArgoCD using Helm with custom values
4. Wait for ArgoCD to be ready
5. Display the admin password

### Manual Installation

Add the ArgoCD Helm repository:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

Create the argocd namespace:

```bash
kubectl create namespace argocd
```

Install ArgoCD:

```bash
helm install argocd argo/argo-cd \
  --namespace argocd \
  --values config/argocd/values.yaml \
  --wait
```

Wait for ArgoCD to be ready:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

## Accessing ArgoCD UI

ArgoCD UI is accessible at:
- URL: http://localhost:30002
- Username: admin
- Password: Retrieve with:

```bash
kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.argocd-server-admin-password}" | base64 -d
```

## Configuration

### Helm Values

The ArgoCD installation uses custom Helm values defined in `config/argocd/values.yaml`:

- **Service Type**: NodePort (mapped to port 30002)
- **Insecure Mode**: Enabled for development (disable in production)
- **Auto-sync**: Enabled by default
- **Resource Limits**: CPU 1000m, Memory 512Mi

### GitOps Repository

The GitOps repository structure is created by running:

```bash
./scripts/setup-gitops-repo.sh
```

This creates:
- `apps/` - ArgoCD Application manifests
- `charts/` - Helm charts for platform workloads
- `values/` - Environment-specific values files

## Adding GitOps Repository to ArgoCD

After creating the GitOps repository, add it to ArgoCD:

1. Access the ArgoCD UI
2. Navigate to Settings → Repositories
3. Click "Connect Repo"
4. Enter your GitOps repository URL
5. Configure authentication if needed

## Creating Applications

Create ArgoCD Application manifests in the GitOps repository under `apps/`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gitops-repo
    targetRevision: HEAD
    path: charts
  destination:
    server: https://kubernetes.default.svc
    namespace: platform-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Verification

Verify ArgoCD is running:

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

Verify ArgoCD can access the cluster:

```bash
argocd cluster list
```

## Troubleshooting

### ArgoCD UI Not Accessible

Check the ArgoCD service:

```bash
kubectl get svc argocd-server -n argocd
```

Check pod logs:

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Sync Not Working

Check ArgoCD application controller logs:

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

Verify repository connection in ArgoCD UI.

### Resource Limits

If pods are getting OOMKilled, increase resource limits in `config/argocd/values.yaml` and reinstall:

```bash
helm upgrade argocd argo/argo-cd \
  --namespace argocd \
  --values config/argocd/values.yaml
```

## Cleanup

To uninstall ArgoCD:

```bash
helm uninstall argocd -n argocd
kubectl delete namespace argocd
```

## Next Steps

After ArgoCD is installed:
1. Set up the GitOps repository
2. Configure ArgoCD to sync from the repository
3. Create application manifests
4. Deploy platform workloads using GitOps
