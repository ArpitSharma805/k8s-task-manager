#!/bin/bash
set -e

# GitOps Repository Setup Script
# This script creates the GitOps repository structure for ArgoCD

echo "=== Setting up GitOps Repository ==="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    if ! command -v git &> /dev/null; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi
    print_success "git is installed"

    echo ""
}

# Create GitOps repository structure
create_gitops_structure() {
    echo "Creating GitOps repository structure..."

    cd "$(dirname "$0")/.."

    # Create base directory
    mkdir -p gitops-repo
    cd gitops-repo

    # Initialize git repository
    git init
    print_success "Git repository initialized"

    # Create directory structure
    mkdir -p apps
    mkdir -p charts
    mkdir -p values

    # Create README
    cat > README.md << 'EOF'
# GitOps Repository

This repository contains the GitOps manifests for the AI-Powered GitOps Platform.

## Structure

- `apps/` - ArgoCD Application manifests
- `charts/` - Helm charts for platform workloads
- `values/` - Environment-specific values files

## Usage

ArgoCD syncs from this repository to deploy workloads to the Kind cluster.
EOF

    print_success "GitOps repository structure created"

    echo ""
}

# Create sample application manifest
create_sample_app() {
    echo "Creating sample application manifest..."

    cd "$(dirname "$0")/../gitops-repo"

    cat > apps/platform-apps.yaml << 'EOF'
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
EOF

    print_success "Sample application manifest created"

    echo ""
}

# Main execution
main() {
    check_prerequisites
    create_gitops_structure
    create_sample_app

    echo "=== GitOps Repository Setup Complete ==="
    echo ""
    echo "Next steps:"
    echo "1. Initialize a real Git repository on GitHub"
    echo "2. Push this structure to the GitOps repository"
    echo "3. Configure ArgoCD to sync from the repository"
}

main "$@"
