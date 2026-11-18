#!/bin/bash

# Harbor Installation Script for AI-Powered GitOps Platform
# This script installs Harbor on the Kind cluster

set -e

# Get script directory and root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi

    if ! command -v helm &> /dev/null; then
        print_error "helm is not installed. Please install helm first."
        exit 1
    fi

    # Check if cluster is accessible
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi

    # Check if Jenkins is running (dependency)
    if ! kubectl get namespace jenkins &> /dev/null; then
        print_warning "Jenkins namespace not found. Jenkins should be installed first."
    fi

    print_success "Prerequisites check passed"
}

# Add Harbor Helm repository
add_helm_repo() {
    print_info "Adding Harbor Helm repository..."

    if helm repo list | grep -q "harbor"; then
        print_warning "Harbor Helm repository already exists. Updating..."
        helm repo update harbor
    else
        helm repo add harbor https://helm.goharbor.io
        helm repo update
    fi

    print_success "Harbor Helm repository added"
}

# Create Harbor namespace
create_namespace() {
    print_info "Creating harbor-system namespace..."

    if kubectl get namespace harbor-system &> /dev/null; then
        print_warning "Namespace harbor-system already exists"
    else
        kubectl create namespace harbor-system
        print_success "Namespace harbor-system created"
    fi
}

# Install Harbor
install_harbor() {
    print_info "Installing Harbor..."

    helm upgrade --install harbor harbor/harbor \
        --namespace harbor-system \
        --values "$ROOT_DIR/config/harbor/values.yaml" \
        --wait \
        --timeout 15m

    print_success "Harbor installed successfully"
}

# Wait for Harbor to be ready
wait_for_harbor() {
    print_info "Waiting for Harbor to be ready..."

    # Wait for all Harbor pods to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=harbor -n harbor-system --timeout=600s

    print_success "Harbor is ready"
}

# Display access information
display_access_info() {
    print_info "Harbor Access Information"
    echo "================================"
    echo ""
    echo "Harbor is deployed with ClusterIP service type."
    echo ""
    echo "To access Harbor UI, use port-forwarding:"
    echo "  kubectl port-forward svc/harbor-portal -n harbor-system 30004:80"
    echo ""
    echo "Then access Harbor at: http://localhost:30004"
    echo ""
    echo "Initial admin password:"
    echo "  Harbor generates a random password on first installation"
    echo "  Retrieve it with:"
    echo "  kubectl get secret harbor-core -n harbor-system -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 -d"
    echo ""
    echo "⚠️  IMPORTANT: Change the default password after first login!"
    echo ""
    echo "Default credentials:"
    echo "  Username: admin"
    echo "  Password: (retrieve with command above)"
    echo ""
    echo "To get the service URL:"
    echo "  kubectl get svc -n harbor-system"
    echo ""
    echo "To view Harbor logs:"
    echo "  kubectl logs -n harbor-system -l app.kubernetes.io/instance=harbor -f"
    echo ""
    echo "To check Harbor pod status:"
    echo "  kubectl get pods -n harbor-system"
    echo ""
}

# Main execution
main() {
    print_info "Starting Harbor installation..."
    echo ""

    check_prerequisites
    add_helm_repo
    create_namespace
    install_harbor
    wait_for_harbor
    display_access_info

    print_success "Harbor installation completed!"
    echo ""
    print_info "Next steps:"
    echo "1. Retrieve initial admin password:"
    echo "   kubectl get secret harbor-core -n harbor-system -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 -d"
    echo "2. Start port-forward:"
    echo "   kubectl port-forward svc/harbor-portal -n harbor-system 30004:80"
    echo "3. Access Harbor UI at http://localhost:30004"
    echo "4. Login with admin and the retrieved password"
    echo "5. Change the password after first login"
    echo "6. Create a new project (e.g., platform-prod)"
    echo "7. Configure Harbor credentials in Jenkins"
    echo "8. Test image push from Jenkins"
}

# Run main function
main
