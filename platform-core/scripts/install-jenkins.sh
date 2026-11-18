#!/bin/bash

# Jenkins Installation Script for AI-Powered GitOps Platform
# This script installs Jenkins on the Kind cluster

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

    print_success "Prerequisites check passed"
}

# Add Jenkins Helm repository
add_helm_repo() {
    print_info "Adding Jenkins Helm repository..."

    if helm repo list | grep -q "jenkins"; then
        print_warning "Jenkins Helm repository already exists. Updating..."
        helm repo update jenkins
    else
        helm repo add jenkins https://charts.jenkins.io
        helm repo update
    fi

    print_success "Jenkins Helm repository added"
}

# Create Jenkins namespace
create_namespace() {
    print_info "Creating jenkins namespace..."

    if kubectl get namespace jenkins &> /dev/null; then
        print_warning "Namespace jenkins already exists"
    else
        kubectl create namespace jenkins
        print_success "Namespace jenkins created"
    fi
}

# Install Jenkins
install_jenkins() {
    print_info "Installing Jenkins..."

    helm upgrade --install jenkins jenkins/jenkins \
        --namespace jenkins \
        --values "$ROOT_DIR/config/jenkins/values.yaml" \
        --wait \
        --timeout 10m

    print_success "Jenkins installed successfully"
}

# Wait for Jenkins to be ready
wait_for_jenkins() {
    print_info "Waiting for Jenkins to be ready..."

    kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=jenkins-controller -n jenkins --timeout=300s

    print_success "Jenkins is ready"
}

# Display access information
display_access_info() {
    print_info "Jenkins Access Information"
    echo "================================"
    echo ""
    echo "Jenkins will be available at: http://localhost:30003"
    echo ""
    echo "Initial admin password:"
    echo "  Username: admin"
    echo "  Password: (auto-generated, retrieve with command below)"
    echo ""
    echo "To get the initial admin password:"
    echo "  kubectl exec -n jenkins sts/jenkins -c jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
    echo ""
    echo "⚠️  IMPORTANT: Change the password after first login!"
    echo ""
    echo "To get the service URL:"
    echo "  kubectl get svc jenkins -n jenkins"
    echo ""
    echo "To view Jenkins logs:"
    echo "  kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller -f"
    echo ""
}

# Main execution
main() {
    print_info "Starting Jenkins installation..."
    echo ""

    check_prerequisites
    add_helm_repo
    create_namespace
    install_jenkins
    wait_for_jenkins
    display_access_info

    print_success "Jenkins installation completed!"
    echo ""
    print_info "Next steps:"
    echo "1. Retrieve initial admin password:"
    echo "   kubectl exec -n jenkins sts/jenkins -c jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword"
    echo "2. Access Jenkins at http://localhost:30003"
    echo "3. Login with admin and the retrieved password"
    echo "4. Change the password after first login"
    echo "5. Install additional plugins if needed"
    echo "6. Configure GitHub credentials"
    echo "7. Create your first pipeline using Jenkinsfile-test"
}

# Run main function
main
