# Syft - Software Bill of Materials (SBOM) Generator

This guide covers Syft installation, configuration, and integration with the AI-Powered GitOps Platform.

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

Syft is a CLI tool and Go library for generating Software Bill of Materials (SBOMs) from container images and filesystems. It supports multiple output formats including SPDX and CycloneDX.

## Installation

Syft is installed via the `install-security-tools.sh` script.

```bash
./platform-core/scripts/install-security-tools.sh
```

Or install manually:

```bash
# Linux
wget -qO - https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# macOS
brew install syft
```

**Note:** No sudo required for Syft installation.

## Configuration

### Environment Variables

```bash
# Set custom CA certificate (for corporate environments)
export SSL_CERT_FILE=/path/to/DellRoot2018.cer

# Set timeout for analysis
export SYFT_TIMEOUT=10m

# Set custom cache directory
export SYFT_CACHE_DIR=/path/to/cache
```

## SBOM Generation

### Generate from Container Image

```bash
# SPDX JSON format
syft localhost:30004/platform-prod/nginx:alpine -o spdx-json=sbom.spdx.json

# CycloneDX JSON format
syft localhost:30004/platform-prod/nginx:alpine -o cyclonedx-json=sbom.cyclonedx.json

# Table format (default)
syft localhost:30004/platform-prod/nginx:alpine -o table
```

**Important:** Syft uses the syntax `-o format=file` to specify output format and file in one command. The old syntax `-o format -o file` is deprecated.

### Generate from Filesystem

```bash
# SPDX JSON format
syft /path/to/project -o spdx-json=sbom.spdx.json

# CycloneDX JSON format
syft /path/to/project -o cyclonedx-json=sbom.cyclonedx.json
```

### Generate with Custom Output File

```bash
# SPDX JSON to file
syft localhost:30004/platform-prod/nginx:alpine -o spdx-json=sbom.spdx.json

# CycloneDX JSON to file
syft localhost:30004/platform-prod/nginx:alpine -o cyclonedx-json=sbom.cyclonedx.json
```

## Output Formats

### SPDX (Software Package Data Exchange)

SPDX is a standard format for communicating SBOM information.

```bash
# SPDX JSON
syft localhost:30004/platform-prod/nginx:alpine -o spdx-json=sbom.spdx.json

# SPDX Tag-Value
syft localhost:30004/platform-prod/nginx:alpine -o spdx-tag-value=sbom.spdx
```

### CycloneDX

CycloneDX is another SBOM standard with enhanced security features.

```bash
# CycloneDX JSON
syft localhost:30004/platform-prod/nginx:alpine -o cyclonedx-json=sbom.cyclonedx.json

# CycloneDX XML
syft localhost:30004/platform-prod/nginx:alpine -o cyclonedx-xml=sbom.cyclonedx.xml
```

### Table Format

Human-readable table output for quick inspection.

```bash
syft localhost:30004/platform-prod/nginx:alpine -o table
```

## Harbor Integration

### Harbor Native SBOM Support

Harbor can generate and store SBOMs for images. Enable in Harbor UI:

1. Go to your project
2. Click "Configuration"
3. Enable "Generate SBOM for images"
4. Select SBOM format (SPDX or CycloneDX)
5. Click "Save"

### View SBOM in Harbor

1. Go to your project
2. Click "Repositories"
3. Click on an image
4. Click "Artifacts" tab
5. Click "SBOM" to view

### Generate SBOM for Harbor Images

**Local Validation (with port-forward):**
```bash
# Start port-forward
kubectl port-forward svc/harbor-portal -n harbor-system 30004:80

# Generate SBOM for image in Harbor
syft localhost:30004/platform-prod/nginx:alpine -o cyclonedx-json=sbom.cyclonedx.json
```

**Jenkins Agent (cluster-internal):**
```bash
# Generate SBOM for image in Harbor
syft harbor-core.harbor-system.svc.cluster.local/platform-prod/nginx:alpine -o cyclonedx-json=sbom.cyclonedx.json
```

## Jenkins Integration

### Archive SBOM as Build Artifact

```groovy
stage('Generate SBOM') {
    steps {
        script {
            sh """
                # Generate SPDX SBOM
                syft localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG} \
                    -o spdx-json \
                    -o sbom-${IMAGE_TAG}.spdx.json

                # Generate CycloneDX SBOM
                syft localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG} \
                    -o cyclonedx-json \
                    -o sbom-${IMAGE_TAG}.cyclonedx.json
            """
        }
        archiveArtifacts artifacts: 'sbom-*.json', fingerprint: true
    }
}
```

### Archive Multiple SBOM Formats

```groovy
stage('Generate SBOM') {
    steps {
        script {
            sh """
                # Generate SPDX JSON
                syft localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG} \
                    -o spdx-json \
                    -o sbom-${IMAGE_TAG}.spdx.json

                # Generate CycloneDX JSON
                syft localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG} \
                    -o cyclonedx-json \
                    -o sbom-${IMAGE_TAG}.cyclonedx.json

                # Generate Table for quick view
                syft localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG} \
                    -o table \
                    -o sbom-${IMAGE_TAG}.txt
            """
        }
        archiveArtifacts artifacts: 'sbom-*.*', fingerprint: true
    }
}
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

**Configuration for Syft:**

If the certificate is pre-installed in the system trust store, Syft will automatically use it. If using a custom certificate location:

```bash
# Set CA certificate for Syft
export SSL_CERT_FILE=/path/to/DellRoot2018.cer
```

### Harbor without TLS

For Harbor deployed without TLS (local development):

```bash
# Syft may need to allow insecure connections
# This is typically handled by Podman's configuration
# Ensure Harbor is accessible via port-forward
kubectl port-forward svc/harbor-portal -n harbor-system 30004:80
```

## Advanced Usage

### Filter Packages

```bash
# Filter by package name
syft localhost:30004/platform-prod/nginx:alpine --filter "name=nginx"

# Filter by package type
syft localhost:30004/platform-prod/nginx:alpine --filter "type=apk"
```

### Exclude Packages

```bash
# Exclude dev dependencies
syft /path/to/project --exclude "dev"

# Exclude specific directories
syft /path/to/project --exclude "**/node_modules/**"
```

### Custom SBOM Metadata

```bash
# Add custom metadata
syft localhost:30004/platform-prod/nginx:alpine \
    -o cyclonedx-json \
    --metadata-file metadata.json
```

## Validation

### Validate Syft Installation

```bash
syft --version
```

### Validate SBOM Generation

```bash
# Generate SPDX SBOM
syft localhost:30004/platform-prod/nginx:alpine -o spdx-json

# Generate CycloneDX SBOM
syft localhost:30004/platform-prod/nginx:alpine -o cyclonedx-json

# Verify output files
ls -la sbom.*
```

### Validate SBOM Content

```bash
# View SPDX SBOM
cat sbom.spdx.json | jq

# View CycloneDX SBOM
cat sbom.cyclonedx.json | jq
```

## Best Practices

1. **Generate Multiple Formats**: Provide both SPDX and CycloneDX for compatibility
2. **Archive SBOMs**: Store SBOMs as Jenkins artifacts for audit trails
3. **Version Control**: Store SBOMs in version control for compliance
4. **Compare SBOMs**: Use SBOMs to detect dependency changes
5. **Automate Generation**: Integrate SBOM generation into CI/CD pipeline
6. **Validate SBOMs**: Use tools to validate SBOM format and completeness
7. **Monitor Dependencies**: Track SBOMs for security and license compliance
8. **Document Format**: Document which SBOM format is required by your organization

## Troubleshooting

### Image Not Found

```bash
# Ensure Harbor is accessible
kubectl port-forward svc/harbor-portal -n harbor-system 30004:80

# Verify image exists
podman images | grep localhost:30004
```

### Certificate Errors

```bash
# Set CA certificate
export SSL_CERT_FILE=/path/to/DellRoot2018.cer

# Or add to system trust store
sudo cp DellRoot2018.cer /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### Timeout Errors

```bash
# Increase timeout
export SYFT_TIMEOUT=15m
```

### Memory Issues

```bash
# Limit scope
syft /path/to/project --exclude "**/node_modules/**"
```

## Additional Resources

- [Syft Documentation](https://github.com/anchore/syft)
- [SPDX Specification](https://spdx.dev/)
- [CycloneDX Specification](https://cyclonedx.org/)
- [SBOM Best Practices](https://ntia.gov/page/sbom-resources)
