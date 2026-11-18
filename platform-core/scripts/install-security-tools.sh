#!/bin/bash

# Security Tools Installation Script for AI-Powered GitOps Platform
# This script installs Trivy, Syft, and Cosign for container security
# Note: This script installs tools locally, not in the cluster

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

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [[ -f /etc/debian_version ]]; then
            DISTRO="debian"
        elif [[ -f /etc/redhat-release ]]; then
            DISTRO="redhat"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        print_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    print_success "Detected OS: $OS"
}

# Check if Podman is installed
check_podman() {
    print_info "Checking for Podman..."

    if command -v podman &> /dev/null; then
        PODMAN_VERSION=$(podman --version)
        print_success "Podman found: $PODMAN_VERSION"
    else
        print_warning "Podman not found. Please install Podman first."
        print_info "Visit: https://podman.io/getting-started/installation"
        exit 1
    fi
}

# Install Trivy
install_trivy() {
    print_info "Installing Trivy..."

    if command -v trivy &> /dev/null; then
        TRIVY_VERSION=$(trivy --version)
        print_warning "Trivy already installed: $TRIVY_VERSION"
        read -p "Reinstall Trivy? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    if [[ "$OS" == "linux" ]]; then
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
        echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
        sudo apt-get update
        sudo apt-get install -y trivy
    elif [[ "$OS" == "macos" ]]; then
        brew install trivy
    fi

    print_success "Trivy installed successfully"
}

# Install Syft
install_syft() {
    print_info "Installing Syft..."

    if command -v syft &> /dev/null; then
        SYFT_VERSION=$(syft --version)
        print_warning "Syft already installed: $SYFT_VERSION"
        read -p "Reinstall Syft? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    if [[ "$OS" == "linux" ]]; then
        wget -qO - https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
    elif [[ "$OS" == "macos" ]]; then
        brew install syft
    fi

    print_success "Syft installed successfully"
}

# Install Cosign
install_cosign() {
    print_info "Installing Cosign..."

    if command -v cosign &> /dev/null; then
        COSIGN_VERSION=$(cosign version)
        print_warning "Cosign already installed: $COSIGN_VERSION"
        read -p "Reinstall Cosign? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    if [[ "$OS" == "linux" ]]; then
        wget -qO - https://raw.githubusercontent.com/sigstore/cosign/main/install.sh | sh -s -- -b /usr/local/bin
    elif [[ "$OS" == "macos" ]]; then
        brew install cosign
    fi

    print_success "Cosign installed successfully"
}

# Configure corporate CA
configure_corporate_ca() {
    print_info "Corporate CA Configuration"
    echo "================================"
    echo ""
    echo "If you have a corporate CA certificate (e.g., DellRoot2018.cer),"
    echo "you may need to configure it for the security tools."
    echo ""
    echo "For Trivy:"
    echo "  export TRIVY_SKIP_DB_UPDATE=false"
    echo "  export TRIVY_INSECURE=true (for Harbor without TLS)"
    echo ""
    echo "For Cosign:"
    echo "  export COSIGN_EXPERIMENTAL=1"
    echo "  export SSL_CERT_FILE=/path/to/DellRoot2018.cer"
    echo ""
    print_warning "Corporate CA configuration is manual. See documentation for details."
}

# Verify installations
verify_installations() {
    print_info "Verifying installations..."

    if command -v trivy &> /dev/null; then
        TRIVY_VERSION=$(trivy --version)
        print_success "Trivy: $TRIVY_VERSION"
    else
        print_error "Trivy not found"
    fi

    if command -v syft &> /dev/null; then
        SYFT_VERSION=$(syft --version)
        print_success "Syft: $SYFT_VERSION"
    else
        print_error "Syft not found"
    fi

    if command -v cosign &> /dev/null; then
        COSIGN_VERSION=$(cosign version)
        print_success "Cosign: $COSIGN_VERSION"
    else
        print_error "Cosign not found"
    fi
}

# Display next steps
display_next_steps() {
    print_info "Next Steps"
    echo "============"
    echo ""
    echo "1. Review security tool documentation:"
    echo "   - platform-core/docs/security/trivy.md"
    echo "   - platform-core/docs/security/syft.md"
    echo "   - platform-core/docs/security/cosign.md"
    echo ""
    echo "2. Configure corporate CA if needed (see documentation)"
    echo ""
    echo "3. Test tools with validation commands:"
    echo "   trivy image localhost:30004/platform-prod/nginx:alpine"
    echo "   syft localhost:30004/platform-prod/nginx:alpine -o cyclonedx-json"
    echo "   cosign sign localhost:30004/platform-prod/nginx:alpine"
    echo ""
    echo "4. Integrate with Jenkins pipeline (see pipeline-example.md)"
    echo ""
}

# Main execution
main() {
    print_info "Starting security tools installation..."
    echo ""

    detect_os
    check_podman
    install_trivy
    install_syft
    install_cosign
    configure_corporate_ca
    verify_installations
    display_next_steps

    print_success "Security tools installation completed!"
}

# Run main function
main
