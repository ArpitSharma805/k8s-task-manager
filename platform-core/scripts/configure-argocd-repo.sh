#!/bin/bash
set -e

# ArgoCD Repository Configuration Script
# This script configures ArgoCD to sync from the GitOps repository

echo "=== Configuring ArgoCD GitOps Repository ==="
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

    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    print_success "kubectl is installed"

    if ! command -v argocd &> /dev/null; then
        print_error "argocd CLI is not installed. Please install argocd CLI first."
        exit 1
    fi
    print_success "argocd CLI is installed"

    echo ""
}

# Check ArgoCD is running
check_argocd_running() {
    echo "Checking ArgoCD is running..."

    kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server
    print_success "ArgoCD is running"

    echo ""
}

# Get ArgoCD admin password
get_argocd_password() {
    echo "Getting ArgoCD admin password..."

    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.argocd-server-admin-password}" | base64 -d)
    print_success "ArgoCD admin password retrieved"

    echo ""
}

# Login to ArgoCD
login_argocd() {
    echo "Logging in to ArgoCD..."

    argocd login localhost:30002 --username admin --password "$ARGOCD_PASSWORD" --insecure
    print_success "Logged in to ArgoCD"

    echo ""
}

# Add GitOps repository
add_gitops_repo() {
    echo "Adding GitOps repository to ArgoCD..."

    print_info "Please provide your GitOps repository URL:"
    read -p "Repository URL (e.g., https://github.com/your-org/gitops-repo): " REPO_URL

    if [ -z "$REPO_URL" ]; then
        print_error "Repository URL is required"
        exit 1
    fi

    argocd repo add "$REPO_URL" --name gitops-repo --type git
    print_success "GitOps repository added"

    echo ""
}

# Apply ArgoCD Application manifests
apply_applications() {
    echo "Applying ArgoCD Application manifests..."

    cd "$(dirname "$0")/.."

    kubectl apply -f config/argocd/apps/root-app.yaml
    print_success "Root application applied"

    kubectl apply -f config/argocd/apps/platform-apps.yaml
    print_success "Platform applications applied"

    echo ""
}

# Verify applications
verify_applications() {
    echo "Verifying ArgoCD applications..."

    argocd app list
    print_success "Applications listed"

    echo ""
}

# Main execution
main() {
    check_prerequisites
    check_argocd_running
    get_argocd_password
    login_argocd
    add_gitops_repo
    apply_applications
    verify_applications

    echo "=== ArgoCD GitOps Repository Configuration Complete ==="
    echo ""
    echo "Next steps:"
    echo "1. Verify applications are syncing in ArgoCD UI"
    echo "2. Check sync status: argocd app get root-app"
    echo "3. Monitor sync status in ArgoCD UI at http://localhost:30002"
}

main "$@"
