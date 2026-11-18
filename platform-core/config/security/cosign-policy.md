# Cosign Policy for Image Verification

This document defines the Cosign policy for verifying container images in the AI-Powered GitOps Platform.

## Policy Overview

The Cosign policy enforces the following requirements:
- Images must be signed with a valid signature
- Signatures must include required annotations
- Images must pass vulnerability checks
- Images must have valid SBOMs

## Policy Definition

```json
{
  "type": "cosign",
  "spec": {
    "image": "localhost:30004/platform-prod/*",
    "annotations": [
      {
        "key": "build.number",
        "type": "string"
      },
      {
        "key": "build.url",
        "type": "string"
      },
      {
        "key": "git.commit",
        "type": "string"
      },
      {
        "key": "git.branch",
        "type": "string"
      }
    ],
    "required": [
      "build.number",
      "build.url"
    ]
  }
}
```

## Policy Usage

### Verify with Policy

```bash
cosign verify --key cosign.pub --policy cosign-policy.json localhost:30004/platform-prod/nginx:alpine
```

### Verify in Jenkins Pipeline

```groovy
stage('Verify with Policy') {
    steps {
        withCredentials([
            file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUB')
        ]) {
            script {
                sh """
                    export COSIGN_INSECURE_SKIP_VERIFY=true

                    # Verify with policy
                    cosign verify --key ${COSIGN_PUB} \
                        --policy platform-core/config/security/cosign-policy.json \
                        localhost:30004/platform-prod/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }
}
```

## Policy Requirements

### Required Annotations

All images must include the following annotations:

- `build.number`: Jenkins build number
- `build.url`: Jenkins build URL

### Optional Annotations

The following annotations are recommended:

- `git.commit`: Git commit SHA
- `git.branch`: Git branch name
- `author`: Commit author
- `timestamp`: Build timestamp

### Signature Requirements

- Images must be signed with the platform's private key
- Signatures must be verifiable with the public key
- Signatures must be stored in Harbor

### SBOM Requirements

- Images must have an associated SBOM
- SBOM must be in SPDX or CycloneDX format
- SBOM must be signed

## Policy Enforcement

### Pre-deployment Verification

Before deploying images, verify:

```bash
# Verify signature
cosign verify --key cosign.pub localhost:30004/platform-prod/nginx:alpine

# Verify with policy
cosign verify --key cosign.pub --policy cosign-policy.json localhost:30004/platform-prod/nginx:alpine

# Verify SBOM
cosign verify --key cosign.pub localhost:30004/platform-prod/nginx:alpine
cosign download sbom localhost:30004/platform-prod/nginx:alpine
```

### ArgoCD Integration

Configure ArgoCD to verify signatures before deployment:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-apps
spec:
  syncPolicy:
    syncOptions:
      - VerifySignature=true
  sources:
    - repoURL: https://github.com/example/platform
      targetRevision: main
      ref: values
```

## Corporate Certificate Handling

### DellRoot2018.cer

For corporate environments with DellRoot2018.cer, the policy should include:

```json
{
  "type": "cosign",
  "spec": {
    "image": "localhost:30004/platform-prod/*",
    "annotations": [
      {
        "key": "build.number",
        "type": "string"
      },
      {
        "key": "build.url",
        "type": "string"
      }
    ],
    "required": [
      "build.number",
      "build.url"
    ],
    "certificate": {
      "path": "/path/to/DellRoot2018.cer",
      "type": "PEM"
    }
  }
}
```

### Harbor without TLS

For Harbor deployed without TLS, set:

```bash
export COSIGN_INSECURE_SKIP_VERIFY=true
```

## Policy Updates

### Update Policy

To update the policy:

1. Edit `cosign-policy.json`
2. Commit to version control
3. Update Jenkins pipeline to use new policy
4. Test policy with existing images

### Rotate Policy

To rotate the policy:

1. Generate new key pair
2. Update policy with new public key
3. Re-sign all images with new key
4. Update Harbor with new public key
5. Remove old key

## Validation

### Validate Policy Syntax

```bash
# Validate JSON syntax
cat cosign-policy.json | jq

# Validate with Cosign
cosign verify --key cosign.pub --policy cosign-policy.json localhost:30004/platform-prod/nginx:alpine
```

### Validate Policy Enforcement

```bash
# Test with image that has all required annotations
cosign verify --key cosign.pub --policy cosign-policy.json localhost:30004/platform-prod/nginx:alpine

# Test with image that is missing annotations (should fail)
# This will fail if image is missing required annotations
```

## Best Practices

1. **Version Control Policies**: Store policies in version control
2. **Document Changes**: Document policy changes and reasons
3. **Test Policies**: Test policies before enforcing
4. **Gradual Rollout**: Roll out policies gradually
5. **Monitor Failures**: Monitor policy verification failures
6. **Update Regularly**: Update policies as requirements change
7. **Use Required Annotations**: Enforce required annotations
8. **Rotate Keys**: Rotate keys periodically
9. **Backup Policies**: Backup policies and keys
10. **Audit Policy**: Audit policy compliance regularly

## Troubleshooting

### Policy Verification Fails

```bash
# Check image has required annotations
cosign verify --key cosign.pub --verbose localhost:30004/platform-prod/nginx:alpine

# Check policy syntax
cat cosign-policy.json | jq
```

### Certificate Errors

```bash
# Set CA certificate
export SSL_CERT_FILE=/path/to/DellRoot2018.cer

# Or allow insecure connections
export COSIGN_INSECURE_SKIP_VERIFY=true
```

### Harbor without TLS

```bash
# Allow insecure connections
export COSIGN_INSECURE_SKIP_VERIFY=true
cosign verify --key cosign.pub --insecure-skip-verify localhost:30004/platform-prod/nginx:alpine
```

## Additional Resources

- [Cosign Policy Documentation](https://docs.sigstore.dev/cosign/policy/)
- [Cosign GitHub](https://github.com/sigstore/cosign)
- [Sigstore Policies](https://docs.sigstore.dev/policies/)
