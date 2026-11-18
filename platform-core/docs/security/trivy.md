# Trivy - Container and Filesystem Security Scanner

This guide covers Trivy installation, configuration, and integration with the AI-Powered GitOps Platform.

## Harbor Access Context

**For Local Validation (Development):**
- Use `localhost:30004` with port-forward
- Requires: `kubectl port-forward svc/harbor-portal -n harbor-system 30004:80`
- Examples in this document use `localhost:30004` for local testing

**For Jenkins Agents (Production/Cluster-Internal):**
- Use `harbor-core.harbor-system.svc.cluster.local`
- No port-forward needed
- Jenkins pipeline uses cluster-internal DNS

**Important:** Replace `localhost:30004` with `harbor-core.harbor-system.svc.cluster.local` when configuring Jenkins pipelines.

## Overview

Trivy is a comprehensive security scanner that detects vulnerabilities, misconfigurations, and secrets in:
- Container images
- Filesystems
- Git repositories
- Kubernetes clusters

## Installation

Trivy is installed via the `install-security-tools.sh` script.

```bash
./platform-core/scripts/install-security-tools.sh
```

Or install manually:

```bash
# Linux (Debian/Ubuntu)
# ⚠️ ONE-TIME ADMINISTRATOR SETUP ONLY. Never execute inside Jenkins pipelines.
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# macOS
brew install trivy
```

## Configuration

### Trivy Configuration File

Create `trivy-config.yaml`:

```yaml
severity:
  - HIGH
  - CRITICAL

vulnerability:
  type:
    - os
    - library

skip-dirs:
  - '**/node_modules/**'
  - '**/vendor/**'

skip-files:
  - '**/*.min.js'

format: table
output: trivy-report.txt
```

### Environment Variables

```bash
# Skip database update (for air-gapped environments)
export TRIVY_SKIP_DB_UPDATE=false

# Allow insecure connections (for Harbor without TLS)
export TRIVY_INSECURE=true

# Set custom CA certificate (for corporate environments)
export TRIVY_CA_CERT=/path/to/DellRoot2018.cer

# Set timeout for scanning
export TRIVY_TIMEOUT=10m
```

## Image Scanning

### Basic Image Scan

```bash
trivy image localhost:30004/platform-prod/nginx:alpine
```

### Scan with Severity Threshold

```bash
# Fail on HIGH or CRITICAL
trivy image --severity HIGH,CRITICAL --exit-code 1 localhost:30004/platform-prod/nginx:alpine
```

### Scan with Configuration File

```bash
trivy image --config trivy-config.yaml localhost:30004/platform-prod/nginx:alpine
```

### Scan with Output Formats

```bash
# JSON output
trivy image --format json --output trivy-report.json localhost:30004/platform-prod/nginx:alpine

# SARIF output (for GitHub Security)
trivy image --format sarif --output trivy-report.sarif localhost:30004/platform-prod/nginx:alpine

# Table output (default)
trivy image --format table localhost:30004/platform-prod/nginx:alpine
```

### Scan Specific Vulnerability Types

```bash
# OS packages only
trivy image --vuln-type os localhost:30004/platform-prod/nginx:alpine

# Library dependencies only
trivy image --vuln-type library localhost:30004/platform-prod/nginx:alpine
```

## Filesystem Scanning

### Scan Local Directory

```bash
trivy fs /path/to/project
```

### Scan with Ignore Policies

```bash
trivy fs --skip-dirs '**/node_modules/**' /path/to/project
```

### Scan with Severity Filter

```bash
trivy fs --severity HIGH,CRITICAL /path/to/project
```

## Harbor Integration

### Harbor Native Scanning

Harbor includes Trivy for image scanning. Enable it in Harbor UI:

1. Go to your project
2. Click "Configuration"
3. Enable "Automatically scan images on push"
4. Configure severity thresholds
5. Click "Save"

### Scan Images Stored in Harbor

```bash
# Scan image from Harbor
trivy image --insecure localhost:30004/platform-prod/nginx:alpine

# Note: --insecure is required for Harbor without TLS
```

### Scan via Harbor API

```bash
# Trigger scan via Harbor API
curl -X POST "http://localhost:30004/api/v2.0/projects/platform-prod/repositories/nginx/artifacts/alpine/scan" \
  -u "admin:<password>"
```

## Ignore Policies

### Create Ignore File

Create `.trivyignore`:

```yaml
# Ignore specific CVEs
CVE-2021-1234
CVE-2021-5678

# Ignore vulnerabilities in specific packages
alpine:3.12:CVE-2021-0001
nginx:1.19:CVE-2021-0002

# Ignore vulnerabilities with specific severity
# LOW vulnerabilities
```

### Use Ignore File

```bash
trivy image --ignore-file .trivyignore localhost:30004/platform-prod/nginx:alpine
```

## Corporate CA Configuration

### DellRoot2018.cer Certificate

For corporate environments with DellRoot2018.cer, the certificate should be pre-installed on the system by administrators.

**Pre-installation Steps (System Administrator):**

```bash
# ⚠️ ONE-TIME ADMINISTRATOR SETUP ONLY. Never execute inside Jenkins pipelines.
# Add certificate to system trust store (requires admin access)
sudo cp DellRoot2018.cer /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

**Configuration for Trivy:**

If the certificate is pre-installed in the system trust store, Trivy will automatically use it. If using a custom certificate location:

```bash
# Set CA certificate for Trivy
export TRIVY_CA_CERT=/path/to/DellRoot2018.cer
```

**Important:** Never attempt to install certificates in CI/CD pipelines. Certificates must be pre-installed by system administrators.

### Harbor without TLS

For Harbor deployed without TLS (local development):

```bash
# Allow insecure connections
export TRIVY_INSECURE=true

# Or use --insecure flag
trivy image --insecure localhost:30004/platform-prod/nginx:alpine
```

**Note:** For Jenkins agents running in-cluster, use the cluster-internal Harbor service address:
```bash
trivy image --insecure harbor-core.harbor-system.svc.cluster.local/platform-prod/nginx:alpine
```

### Database Download Issues

If Trivy cannot download vulnerability database:

```bash
# Use proxy if needed
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080

# Or skip database update (not recommended)
export TRIVY_SKIP_DB_UPDATE=true
```

## Jenkins Integration

### Jenkins Pipeline Example

```groovy
stage('Trivy Scan') {
    steps {
        script {
            sh """
                # Login to Harbor
                podman login localhost:30004 -u ${HARBOR_USER} -p ${HARBOR_PASS}

                # Scan image with Trivy
                trivy image --severity HIGH,CRITICAL --exit-code 1 \
                    --insecure \
                    --format json \
                    --output trivy-report.json \
                    localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG}

                # Log out
                podman logout localhost:30004
            """
        }
        archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true
    }
}
```

### Fail Build on Vulnerabilities

```groovy
stage('Trivy Scan') {
    steps {
        script {
            try {
                sh """
                    trivy image --severity HIGH,CRITICAL --exit-code 1 \
                        --insecure \
                        localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG}
                """
            } catch (Exception e) {
                error "Trivy scan found HIGH or CRITICAL vulnerabilities"
            }
        }
    }
}
```

## Validation

### Validate Trivy Installation

```bash
trivy --version
```

### Validate Image Scan

```bash
# Scan a test image
trivy image localhost:30004/platform-prod/nginx:alpine

# Scan with severity threshold
trivy image --severity HIGH,CRITICAL --exit-code 1 localhost:30004/platform-prod/nginx:alpine
```

### Validate Filesystem Scan

```bash
# Scan current directory
trivy fs .
```

## Best Practices

1. **Scan Early and Often**: Integrate Trivy into CI/CD pipeline
2. **Fail on Critical**: Use `--exit-code 1` with severity thresholds
3. **Fix Vulnerabilities**: Address HIGH and CRITICAL findings promptly
4. **Use Ignore Policies**: Document and review ignore policies regularly
5. **Keep Database Updated**: Ensure Trivy database is current
6. **Scan Multiple Layers**: Scan both OS packages and library dependencies
7. **Archive Reports**: Save scan reports for audit and compliance
8. **Monitor Trends**: Track vulnerability trends over time

## Troubleshooting

### Database Update Fails

```bash
# Check network connectivity
curl -I https://github.com

# Use proxy
export HTTP_PROXY=http://proxy.example.com:8080

# Update database manually
trivy image --download-db-only
```

### Scan Timeout

```bash
# Increase timeout
export TRIVY_TIMEOUT=15m

# Or use --timeout flag
trivy image --timeout 15m localhost:30004/platform-prod/nginx:alpine
```

### Certificate Errors

```bash
# Allow insecure connections (development only)
trivy image --insecure localhost:30004/platform-prod/nginx:alpine

# Or set CA certificate
export TRIVY_CA_CERT=/path/to/DellRoot2018.cer
```

### Memory Issues

```bash
# Limit scan scope
trivy image --vuln-type os localhost:30004/platform-prod/nginx:alpine

# Or skip certain packages
trivy image --skip-dirs '**/node_modules/**' localhost:30004/platform-prod/nginx:alpine
```

## Additional Resources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Trivy GitHub](https://github.com/aquasecurity/trivy)
- [Trivy Configuration](https://aquasecurity.github.io/trivy/latest/docs/configuration/)
- [Harbor Trivy Integration](https://goharbor.io/docs/2.0/administration/configure/#scan-images-on-push)
