# Sample Application Deployment Guide

This guide covers the deployment of the sample application for the AI-Powered GitOps Platform.

## Overview

The sample application is a minimal Node.js Express application that validates the complete DevSecOps platform including Jenkins, Harbor, Trivy, Syft, Cosign, and ArgoCD.

## Application Details

- **Language:** Node.js 18
- **Framework:** Express
- **Port:** 3000
- **Endpoints:**
  - `/` - Welcome message with version
  - `/health` - Health check endpoint
  - `/version` - Version endpoint
  - `/metrics` - Prometheus metrics endpoint

## Prerequisites

- Kind cluster running (Ticket 01)
- ArgoCD installed (Ticket 02)
- Jenkins installed (Ticket 03)
- Harbor installed (Ticket 05)
- Security tools installed (Ticket 04)
- Podman installed on Jenkins agent
- Harbor accessible from Jenkins agent

## Application Structure

```
sample-app/
├── package.json          # Node.js dependencies
├── server.js             # Express application
├── Dockerfile             # Multi-stage container build
└── Jenkinsfile           # Jenkins pipeline definition
```

## Build and Deploy

### Option 1: Manual Build with Podman

```bash
# Navigate to sample-app directory
cd sample-app

# Build image
podman build -t sample-app:latest .

# Tag for Harbor
podman tag sample-app:latest harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app:latest

# Login to Harbor
podman login harbor-core.harbor-system.svc.cluster.local

# Push to Harbor
podman push harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app:latest

# Logout
podman logout harbor-core.harbor-system.svc.cluster.local
```

### Option 2: Jenkins Pipeline

The sample application includes a Jenkinsfile that automates the complete DevSecOps workflow:

1. Checkout source code
2. Build image with Podman
3. Push to Harbor
4. Trivy scan (fail on HIGH/CRITICAL)
5. Generate SBOM (SPDX and CycloneDX)
6. Sign image with Cosign
7. Verify signature
8. Publish artifacts

**To use the Jenkinsfile:**

1. Create a new Pipeline job in Jenkins
2. Configure SCM to point to the repository
3. Set Script Path to `sample-app/Jenkinsfile`
4. Configure required credentials:
   - Harbor credentials
   - Cosign private key
   - Cosign public key
   - Cosign password
5. Run pipeline

## Helm Deployment

### Install Helm Chart

```bash
# Navigate to Helm chart directory
cd deploy/helm/sample-app

# Install chart
helm install sample-app ./sample-app \
  --namespace platform-prod \
  --create-namespace

# Or upgrade if already installed
helm upgrade sample-app ./sample-app \
  --namespace platform-prod
```

### Install with Custom Values

```bash
helm install sample-app ./sample-app \
  --namespace platform-prod \
  --values custom-values.yaml \
  --set image.tag=1.0.0
```

### Uninstall

```bash
helm uninstall sample-app -n platform-prod
```

## ArgoCD Integration

### Add Application to ArgoCD

1. Create Application manifest in GitOps repository:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gitops-repo
    targetRevision: main
    path: deploy/helm/sample-app
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

2. Apply the manifest:

```bash
kubectl apply -f sample-app-application.yaml
```

3. Verify in ArgoCD UI

## Validation

### Validate Application Locally

```bash
# Install dependencies
cd sample-app
npm install

# Start application
npm start

# Test endpoints
curl http://localhost:3000/
curl http://localhost:3000/health
curl http://localhost:3000/version
curl http://localhost:3000/metrics
```

### Validate Container Image

```bash
# Build image
podman build -t sample-app:latest .

# Run container
podman run -p 3000:3000 sample-app:latest

# Test endpoints
curl http://localhost:3000/health
```

### Validate Deployment in Kind

```bash
# Install Helm chart
helm install sample-app ./deploy/helm/sample-app -n platform-prod

# Check pod status
kubectl get pods -n platform-prod

# Check service
kubectl get svc -n platform-prod

# Port-forward to test
kubectl port-forward svc/sample-app -n platform-prod 3000:3000

# Test application
curl http://localhost:3000/health
```

### Validate ArgoCD Sync

1. Update image tag in Helm values
2. Commit and push to GitOps repository
3. Check ArgoCD UI for sync status
4. Verify deployment is updated

## Security Validation

### Validate Trivy Scan

```bash
# Scan image
trivy image --severity HIGH,CRITICAL --exit-code 1 \
  --insecure \
  harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app:latest
```

### Validate SBOM Generation

```bash
# Generate SPDX SBOM
syft harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app:latest \
  -o spdx-json=sbom.spdx.json

# Generate CycloneDX SBOM
syft harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app:latest \
  -o cyclonedx-json=sbom.cyclonedx.json
```

### Validate Cosign Signature

```bash
# Sign image
export COSIGN_INSECURE_SKIP_VERIFY=true
cosign sign --key cosign.key \
  harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app:latest

# Verify signature
cosign verify --key cosign.pub \
  harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app:latest
```

## Troubleshooting

### Application Won't Start

Check pod logs:
```bash
kubectl logs -n platform-prod -l app=sample-app
```

Check pod status:
```bash
kubectl get pods -n platform-prod
```

### Cannot Access Application

Check service:
```bash
kubectl get svc -n platform-prod
```

Port-forward to test:
```bash
kubectl port-forward svc/sample-app -n platform-prod 3000:3000
```

### Harbor Push Fails

Verify Harbor is accessible:
```bash
podman login harbor-core.harbor-system.svc.cluster.local
```

Check Harbor pods:
```bash
kubectl get pods -n harbor-system
```

### Trivy Scan Fails

Check Trivy database:
```bash
trivy image --download-db-only
```

Allow insecure connections:
```bash
trivy image --insecure ...
```

### Cosign Sign Fails

Set environment variable:
```bash
export COSIGN_INSECURE_SKIP_VERIFY=true
```

### ArgoCD Not Syncing

Check Application status:
```bash
kubectl get application sample-app -n argocd
```

Check GitOps repository connection in ArgoCD UI.

## Cleanup

### Remove Application

```bash
# Uninstall Helm chart
helm uninstall sample-app -n platform-prod

# Delete namespace (if empty)
kubectl delete namespace platform-prod
```

### Remove Image from Harbor

1. Access Harbor UI
2. Go to platform-prod project
3. Delete sample-app image

## Next Steps

After the sample application is deployed and validated:

1. Proceed to [Ticket 07: Helm Charts](../issues/07-helm-charts.md)
2. Or proceed to [Ticket 08: GitOps Automation](../issues/08-gitops-automation.md)

## Additional Resources

- [Express Documentation](https://expressjs.com/)
- [Node.js Documentation](https://nodejs.org/)
- [Helm Documentation](https://helm.sh/docs/)
- [ArgoCD Documentation](https://argoproj.github.io/argo-cd/)
