#!/bin/bash
set -e

# ArgoCD Installation Script for AI-Powered GitOps Platform
# This script installs ArgoCD on the Kind cluster using Helm

echo "=== Installing ArgoCD ==="
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

    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed. Please install Helm first."
        exit 1
    fi
    print_success "Helm is installed"

    echo ""
}

# Add ArgoCD Helm repository
add_argocd_repo() {
    echo "Adding ArgoCD Helm repository..."

    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    print_success "ArgoCD Helm repository added"

    echo ""
}

# Create argocd namespace
create_namespace() {
    echo "Creating argocd namespace..."

    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace 'argocd' created"

    echo ""
}

# Install ArgoCD using Helm
install_argocd() {
    echo "Installing ArgoCD using Helm..."

    cd "$(dirname "$0")/.."

    helm install argocd argo/argo-cd \
        --namespace argocd \
        --values config/argocd/values.yaml \
        --wait

    print_success "ArgoCD installed"

    echo ""
}

# Wait for ArgoCD to be ready
wait_for_argocd() {
    echo "Waiting for ArgoCD to be ready..."

    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    print_success "ArgoCD is ready"

    echo ""
}

# Get ArgoCD admin password
get_password() {
    echo "Getting ArgoCD admin password..."

    argocd_initial_password=$(kubectl -n argocd get secret argocd-secret -o jsonpath="{.data.argocd-server-admin-password}" | base64 -d)
    print_success "ArgoCD admin password retrieved"

    echo ""
    echo "ArgoCD UI is accessible at: http://localhost:30002"
    echo "Username: admin"
    echo "Password: $argocd_initial_password"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    add_argocd_repo
    create_namespace
    install_argocd
    wait_for_argocd
    get_password

    echo "=== ArgoCD Installation Complete ==="
    echo ""
    echo "Next steps:"
    echo "1. Create GitOps repository structure"
    echo "2. Configure ArgoCD to sync from GitOps repository"
    echo "3. Create ArgoCD Application resources"
}

main "$@"
