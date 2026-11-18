# ArgoCD Sample Application Deployment Guide

This guide covers deploying the sample application using ArgoCD GitOps workflow.

## Overview

The sample application is deployed via ArgoCD using a GitOps workflow. Changes to the GitOps repository trigger automatic deployment to the Kind cluster.

## GitOps Structure

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

## Application Manifest

The ArgoCD Application manifest defines how ArgoCD syncs the Helm chart:

- **Source:** `deploy/helm/sample-app` from GitOps repository
- **Destination:** `platform-prod` namespace
- **Sync Policy:** Automatic with prune and self-heal

## Deployment Steps

### 1. Apply Application Manifest

```bash
kubectl apply -f gitops/apps/sample-app/kustomization.yaml
```

### 2. Verify in ArgoCD UI

1. Access ArgoCD UI at http://localhost:30002
2. Navigate to Applications
3. Verify sample-app is synced and healthy

### 3. Update Application

To update the application:

1. Update image tag in `gitops/environments/dev/sample-app-values.yaml`
2. Commit and push to GitOps repository
3. ArgoCD automatically detects change and syncs deployment
4. Verify in ArgoCD UI

## Validation

### Verify Deployment

```bash
# Check pod status
kubectl get pods -n platform-prod -l app=sample-app

# Check service
kubectl get svc -n platform-prod

# Port-forward to test
kubectl port-forward svc/sample-app -n platform-prod 3000:3000

# Test application
curl http://localhost:3000/health
```

### Verify ArgoCD Sync

1. Check ArgoCD UI for sync status
2. Verify application shows "Synced" and "Healthy"
3. Check sync history for recent changes

## Troubleshooting

### Application Not Syncing

Check Application status:
```bash
kubectl get application sample-app -n argocd
```

Check ArgoCD logs:
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Sync Fails

Check Operation phase in ArgoCD UI for detailed error messages.

### Image Pull Fails

Verify Harbor is accessible from cluster:
```bash
kubectl run -it --rm debug --image=harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app:1.0.0 -- sh
```

## Cleanup

```bash
kubectl delete application sample-app -n argocd
```
