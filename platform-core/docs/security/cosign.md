# Cosign - Container Image Signing and Verification

This guide covers Cosign installation, configuration, and integration with the AI-Powered GitOps Platform.

## Harbor Access Context

**For Local Validation (Development):**
- Use `localhost:30004` with port-forward
- Requires: `kubectl port-forward svc/harbor-portal -n harbor-system 30004:80`
- Examples in this document use `localhost:30004` for local testing
- Requires: `export COSIGN_INSECURE_SKIP_VERIFY=true` for HTTP registry

**For Jenkins Agents (Production/Cluster-Internal):**
- Use `harbor-core.harbor-system.svc.cluster.local`
- No port-forward needed
- Jenkins pipeline uses cluster-internal DNS
- Requires: `export COSIGN_INSECURE_SKIP_VERIFY=true` for HTTP registry

**Important:** Replace `localhost:30004` with `harbor-core.harbor-system.svc.cluster.local` when configuring Jenkins pipelines. Always set `COSIGN_INSECURE_SKIP_VERIFY=true` for Harbor HTTP registry.

## Overview

Cosign is a tool for signing and verifying container images and other artifacts. It provides:
- Image signing and verification
- Keyless signing (with Fulcio)
- SBOM signing
- Policy enforcement
- Integration with OCI registries

## Installation

Cosign is installed via the `install-security-tools.sh` script.

```bash
./platform-core/scripts/install-security-tools.sh
```

Or install manually:

```bash
# Linux
wget -qO - https://raw.githubusercontent.com/sigstore/cosign/main/install.sh | sh -s -- -b /usr/local/bin

# macOS
brew install cosign
```

**Note:** No sudo required for Cosign installation.

## Configuration

### Environment Variables

```bash
# Enable experimental features
export COSIGN_EXPERIMENTAL=1

# Set custom CA certificate (for corporate environments)
export SSL_CERT_FILE=/path/to/DellRoot2018.cer

# Set timeout for operations
export COSIGN_TIMEOUT=10m

# Set OIDC issuer (for keyless signing)
export COSIGN_OIDC_ISSUER=https://token.actions.githubusercontent.com
```

## Key Pair Generation

### Generate Key Pair

```bash
# Generate new key pair
cosign generate-key-pair

# This creates:
# - cosign.key (private key)
# - cosign.pub (public key)
```

### Generate with Password

```bash
# Generate with password protection
cosign generate-key-pair --password
```

### Generate KMS Key

```bash
# Generate key in AWS KMS
cosign generate-key-pair --kms awskms://...

# Generate key in Azure Key Vault
cosign generate-key-pair --kms azurekms://...
```

## Image Signing

### Sign Image with Key Pair

```bash
# Sign image
cosign sign --key cosign.key localhost:30004/platform-prod/nginx:alpine

# Sign with password
cosign sign --key cosign.key localhost:30004/platform-prod/nginx:alpine
```

### Sign with Environment Variable

```bash
# Set private key as environment variable
export COSIGN_PRIVATE_KEY=$(cat cosign.key)

# Sign image
cosign sign --key env://COSIGN_PRIVATE_KEY localhost:30004/platform-prod/nginx:alpine
```

### Sign with Annotations

```bash
# Sign with custom annotations
cosign sign --key cosign.key \
    -a "build.url=https://jenkins.example.com/job/123" \
    -a "commit.sha=abc123" \
    localhost:30004/platform-prod/nginx:alpine
```

### Sign SBOM

```bash
# Sign SBOM
cosign sign --key cosign.key sbom.spdx.json

# Sign and attach SBOM to image
cosign attach sbom --sbom sbom.spdx.json localhost:30004/platform-prod/nginx:alpine
cosign sign --key cosign.key localhost:30004/platform-prod/nginx:alpine
```

## Image Verification

### Verify Image with Public Key

```bash
# Verify image
cosign verify --key cosign.pub localhost:30004/platform-prod/nginx:alpine

# Verify with annotations
cosign verify --key cosign.pub -a "build.url" localhost:30004/platform-prod/nginx:alpine
```

### Verify with Public Key from Registry

```bash
# Store public key in Harbor
cosign verify --key cosign.pub localhost:30004/platform-prod/nginx:alpine

# Or store in OCI registry
cosign put --key cosign.pub localhost:30004/platform-prod/cosign.pub
cosign verify --key localhost:30004/platform-prod/cosign.pub localhost:30004/platform-prod/nginx:alpine
```

### Verify with Policy

```bash
# Verify with policy
cosign verify --key cosign.key --policy policy.json localhost:30004/platform-prod/nginx:alpine
```

## Harbor Integration

### Harbor Native Signature Support

Harbor supports Cosign signatures. Enable in Harbor UI:

1. Go to your project
2. Click "Configuration"
3. Enable "Prevent vulnerable images from running"
4. Configure policy
5. Click "Save"

### Sign Images in Harbor

```bash
# Sign image stored in Harbor
cosign sign --key cosign.key localhost:30004/platform-prod/nginx:alpine

# Signature is stored in Harbor as an artifact
```

### Verify Images in Harbor

```bash
# Verify image in Harbor
cosign verify --key cosign.pub localhost:30004/platform-prod/nginx:alpine
```

### View Signatures in Harbor UI

1. Go to your project
2. Click "Repositories"
3. Click on an image
4. Click "Artifacts" tab
5. View signatures

## Key Storage Recommendations

### For Development

Store keys in secure local directory:

```bash
mkdir -p ~/.cosign
mv cosign.key ~/.cosign/
mv cosign.pub ~/.cosign/
chmod 600 ~/.cosign/cosign.key
```

### For Production

Use KMS for key storage:

```bash
# AWS KMS
cosign generate-key-pair --kms awskms://arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

# Azure Key Vault
cosign generate-key-pair --kms azurekms://vaultname.vault.azure.net/keys/keyname
```

### For Jenkins

Store keys in Jenkins credentials:

1. Go to **Manage Jenkins** → **Credentials**
2. Click **System** → **Global credentials**
3. Click **Add Credentials**
4. Select **Secret File**
5. Upload `cosign.key`
6. Give it an ID (e.g., `cosign-private-key`)
7. Repeat for `cosign.pub` (ID: `cosign-public-key`)

## Jenkins Integration

### Sign Image in Pipeline

```groovy
stage('Sign Image') {
    steps {
        withCredentials([
            file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY'),
            string(credentialsId: 'cosign-password', variable: 'COSIGN_PASSWORD')
        ]) {
            script {
                sh """
                    export COSIGN_PASSWORD=${COSIGN_PASSWORD}
                    cosign sign --key ${COSIGN_KEY} \
                        -a "build.number=${BUILD_NUMBER}" \
                        -a "build.url=${BUILD_URL}" \
                        localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }
}
```

### Verify Image in Pipeline

```groovy
stage('Verify Signature') {
    steps {
        withCredentials([
            file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUB')
        ]) {
            script {
                sh """
                    cosign verify --key ${COSIGN_PUB} \
                        localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }
}
```

### Sign and Verify in Pipeline

```groovy
stage('Sign and Verify') {
    steps {
        withCredentials([
            file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY'),
            file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUB'),
            string(credentialsId: 'cosign-password', variable: 'COSIGN_PASSWORD')
        ]) {
            script {
                sh """
                    export COSIGN_PASSWORD=${COSIGN_PASSWORD}

                    # Sign image
                    cosign sign --key ${COSIGN_KEY} \
                        -a "build.number=${BUILD_NUMBER}" \
                        localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG}

                    # Verify signature
                    cosign verify --key ${COSIGN_PUB} \
                        localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
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

**Configuration for Cosign:**

If the certificate is pre-installed in the system trust store, Cosign will automatically use it. If using a custom certificate location:

```bash
# Set CA certificate for Cosign
export SSL_CERT_FILE=/path/to/DellRoot2018.cer
```

**Important:** Never attempt to install certificates in CI/CD pipelines. Certificates must be pre-installed by system administrators.

### Harbor without TLS

For Harbor deployed without TLS (local development):

```bash
# Allow insecure connections
export COSIGN_INSECURE_SKIP_VERIFY=true

# Or use --insecure-skip-verify flag
cosign sign --key cosign.key --insecure-skip-verify localhost:30004/platform-prod/nginx:alpine
```

**Important for Harbor HTTP Registry:**

Cosign requires special handling for HTTP (non-TLS) registries:

1. **Set environment variable:**
   ```bash
   export COSIGN_INSECURE_SKIP_VERIFY=true
   ```

2. **Use --insecure-skip-verify flag:**
   ```bash
   cosign sign --key cosign.key --insecure-skip-verify localhost:30004/platform-prod/nginx:alpine
   ```

3. **For cluster-internal Harbor (Jenkins agents):**
   ```bash
   cosign sign --key cosign.key --insecure-skip-verify \
       harbor-core.harbor-system.svc.cluster.local/platform-prod/nginx:alpine
   ```

**Note:** Harbor HTTP registry requires `COSIGN_INSECURE_SKIP_VERIFY=true` for both signing and verification operations. This is acceptable for local development only. In production, Harbor should use TLS with valid certificates.

## Certificate Rotation Process

### Rotate Keys

```bash
# Generate new key pair
cosign generate-key-pair

# Re-sign all images with new key
cosign sign --key cosign.key localhost:30004/platform-prod/nginx:alpine

# Update public key in Harbor
cosign put --key cosign.pub localhost:30004/platform-prod/cosign.pub

# Remove old key (after verification)
rm old-cosign.key
rm old-cosign.pub
```

### Rotate Certificate

```bash
# ⚠️ ONE-TIME ADMINISTRATOR SETUP ONLY. Never execute inside Jenkins pipelines.
# Update DellRoot2018.cer
sudo cp new-DellRoot2018.cer /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Verify tools work with new certificate
cosign verify --key cosign.pub localhost:30004/platform-prod/nginx:alpine
```

## Validation

### Validate Cosign Installation

```bash
cosign version
```

### Validate Key Generation

```bash
# Generate key pair
cosign generate-key-pair

# Verify files exist
ls -la cosign.key cosign.pub
```

### Validate Image Signing

```bash
# Sign image
cosign sign --key cosign.key localhost:30004/platform-prod/nginx:alpine

# Verify signature
cosign verify --key cosign.pub localhost:30004/platform-prod/nginx:alpine
```

## Best Practices

1. **Protect Private Keys**: Never commit private keys to version control
2. **Use KMS in Production**: Store keys in AWS KMS or Azure Key Vault
3. **Sign All Images**: Sign every image pushed to registry
4. **Verify Before Deploy**: Verify signatures before deploying images
5. **Use Annotations**: Add build metadata to signatures
6. **Rotate Keys Regularly**: Rotate keys periodically (e.g., every 90 days)
7. **Document Key Rotation**: Document key rotation process and schedule
8. **Monitor Signatures**: Monitor signature verification failures
9. **Use Policies**: Enforce policies with Cosign policy verification
10. **Backup Keys**: Securely backup private keys

## Troubleshooting

### Key Not Found

```bash
# Verify key file exists
ls -la cosign.key

# Check file permissions
chmod 600 cosign.key
```

### Signature Verification Fails

```bash
# Check signature exists
cosign triangulate localhost:30004/platform-prod/nginx:alpine

# Verify with verbose output
cosign verify --key cosign.pub --verbose localhost:30004/platform-prod/nginx:alpine
```

### Certificate Errors

```bash
# Allow insecure connections (development only)
export COSIGN_INSECURE_SKIP_VERIFY=true

# Or set CA certificate
export SSL_CERT_FILE=/path/to/DellRoot2018.cer
```

### Harbor without TLS

```bash
# Allow insecure connections
cosign sign --key cosign.key --insecure-skip-verify localhost:30004/platform-prod/nginx:alpine
```

## Additional Resources

- [Cosign Documentation](https://docs.sigstore.dev/cosign/)
- [Cosign GitHub](https://github.com/sigstore/cosign)
- [Sigstore](https://sigstore.dev/)
- [Harbor Cosign Integration](https://goharbor.io/docs/2.0/administration/configure/#cosign)
