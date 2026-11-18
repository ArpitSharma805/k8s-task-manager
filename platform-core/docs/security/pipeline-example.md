# Security Pipeline Example - Complete Jenkins Pipeline

This document provides a complete Jenkins pipeline example that integrates Trivy, Syft, and Cosign for container security and software supply chain controls.

## Pipeline Overview

The pipeline performs the following steps:
1. Checkout source code
2. Build image with Podman
3. Push image to Harbor
4. Trivy scan image (fail on HIGH/CRITICAL)
5. Generate SBOM using Syft (SPDX and CycloneDX)
6. Archive SBOM artifacts
7. Sign image with Cosign
8. Verify signature
9. Publish build artifacts

## Prerequisites

- Jenkins installed and configured
- Harbor installed and accessible from Jenkins agent
- Podman installed on Jenkins agent
- Trivy, Syft, and Cosign installed on Jenkins agent
- Harbor credentials configured in Jenkins
- Cosign key pair configured in Jenkins credentials
- Harbor service accessible via cluster-internal DNS or network

## Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        // Harbor configuration
        // Use cluster-internal Harbor service address for Jenkins agents
        // For Kind cluster with Harbor in harbor-system namespace:
        HARBOR_REGISTRY = "harbor-core.harbor-system.svc.cluster.local"
        HARBOR_PROJECT = "platform-prod"
        IMAGE_NAME = "sample-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"

        // Security tool configuration
        TRIVY_SEVERITY = "HIGH,CRITICAL"
        COSIGN_ANNOTATIONS = "build.number=${BUILD_NUMBER},build.url=${BUILD_URL}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build Image with Podman') {
            steps {
                echo 'Building container image with Podman...'
                sh """
                    podman build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Push to Harbor') {
            steps {
                echo 'Pushing image to Harbor...'
                withCredentials([
                    usernamePassword(
                        credentialsId: 'harbor-credentials',
                        usernameVariable: 'HARBOR_USER',
                        passwordVariable: 'HARBOR_PASS'
                    )
                ]) {
                    sh """
                        # Tag image for Harbor
                        podman tag ${IMAGE_NAME}:${IMAGE_TAG} ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}

                        # Login to Harbor
                        echo ${HARBOR_PASS} | podman login ${HARBOR_REGISTRY} -u ${HARBOR_USER} --password-stdin

                        # Push image
                        podman push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}

                        # Logout
                        podman logout ${HARBOR_REGISTRY}
                    """
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                echo 'Scanning image with Trivy...'
                script {
                    try {
                        sh """
                            # Scan image with Trivy
                            trivy image \
                                --severity ${TRIVY_SEVERITY} \
                                --exit-code 1 \
                                --insecure \
                                --format json \
                                --output trivy-report-${IMAGE_TAG}.json \
                                ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    } catch (Exception e) {
                        error "Trivy scan found HIGH or CRITICAL vulnerabilities. Build failed."
                    }
                }
                archiveArtifacts artifacts: "trivy-report-${IMAGE_TAG}.json", fingerprint: true
            }
        }

        stage('Generate SBOM') {
            steps {
                echo 'Generating SBOM with Syft...'
                sh """
                    # Generate SPDX SBOM
                    syft ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG} \
                        -o spdx-json=sbom-${IMAGE_TAG}.spdx.json

                    # Generate CycloneDX SBOM
                    syft ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG} \
                        -o cyclonedx-json=sbom-${IMAGE_TAG}.cyclonedx.json

                    # Generate table for quick view
                    syft ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG} \
                        -o table=sbom-${IMAGE_TAG}.txt
                """
                archiveArtifacts artifacts: "sbom-${IMAGE_TAG}.*", fingerprint: true
            }
        }

        stage('Sign Image') {
            steps {
                echo 'Signing image with Cosign...'
                withCredentials([
                    file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY'),
                    string(credentialsId: 'cosign-password', variable: 'COSIGN_PASSWORD')
                ]) {
                    script {
                        sh """
                            export COSIGN_PASSWORD=${COSIGN_PASSWORD}
                            export COSIGN_INSECURE_SKIP_VERIFY=true

                            # Sign image with annotations
                            cosign sign --key ${COSIGN_KEY} \
                                -a "build.number=${BUILD_NUMBER}" \
                                -a "build.url=${BUILD_URL}" \
                                -a "git.commit=${GIT_COMMIT}" \
                                -a "git.branch=${GIT_BRANCH}" \
                                ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Verify Signature') {
            steps {
                echo 'Verifying image signature...'
                withCredentials([
                    file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUB')
                ]) {
                    script {
                        sh """
                            export COSIGN_INSECURE_SKIP_VERIFY=true

                            # Verify signature
                            cosign verify --key ${COSIGN_PUB} \
                                ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}
                        """
                    }
                }
            }
        }

        stage('Publish Artifacts') {
            steps {
                echo 'Publishing build artifacts...'
                sh """
                    # Create artifact summary
                    echo "Build Number: ${BUILD_NUMBER}" > artifacts-summary.txt
                    echo "Image: ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}" >> artifacts-summary.txt
                    echo "Git Commit: ${GIT_COMMIT}" >> artifacts-summary.txt
                    echo "Git Branch: ${GIT_BRANCH}" >> artifacts-summary.txt
                    echo "Build URL: ${BUILD_URL}" >> artifacts-summary.txt
                """
                archiveArtifacts artifacts: 'artifacts-summary.txt', fingerprint: true
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
            echo "Image: ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}"
            echo "SBOMs archived: sbom-${IMAGE_TAG}.spdx.json, sbom-${IMAGE_TAG}.cyclonedx.json"
            echo "Trivy report archived: trivy-report-${IMAGE_TAG}.json"
            echo "Image signed and verified"
        }
        failure {
            echo '❌ Pipeline failed!'
            echo 'Check the console output for details.'
        }
        always {
            echo 'Cleaning up...'
            sh """
                # Remove local image
                podman rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                podman rmi ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG} || true
            """
            cleanWs()
        }
    }
}
```

## Pipeline Configuration

### Required Jenkins Credentials

1. **Harbor Credentials** (`harbor-credentials`)
   - Type: Username with password
   - Username: Harbor username
   - Password: Harbor password

2. **Cosign Private Key** (`cosign-private-key`)
   - Type: Secret File
   - File: `cosign.key`

3. **Cosign Public Key** (`cosign-public-key`)
   - Type: Secret File
   - File: `cosign.pub`

4. **Cosign Password** (`cosign-password`)
   - Type: Secret text
   - Secret: Cosign key password

### Harbor Configuration

**For Jenkins Agents (Production/Cluster-Internal):**
- **Registry:** `harbor-core.harbor-system.svc.cluster.local`
- **Project:** `platform-prod`
- **Access:** Cluster-internal DNS (no port-forward needed)

**For Local Validation (Development):**
- **Registry:** `localhost:30004`
- **Project:** `platform-prod`
- **Access:** Requires port-forward: `kubectl port-forward svc/harbor-portal -n harbor-system 30004:80`

**Important:** The Jenkinsfile uses cluster-internal Harbor address for Jenkins agents. For local testing/validation, use localhost:30004 with port-forward.

### Security Tool Configuration

- **Trivy Severity:** HIGH,CRITICAL
- **Trivy Exit Code:** 1 (fail on vulnerabilities)
- **Syft Formats:** SPDX JSON, CycloneDX JSON, Table
- **Cosign Annotations:** build.number, build.url, git.commit, git.branch

## Pipeline Stages Explained

### 1. Checkout
- Checks out source code from SCM
- Uses Jenkins' built-in `checkout scm` step

### 2. Build Image with Podman
- Builds container image using Podman
- Tags image with build number
- Uses local Dockerfile

### 3. Push to Harbor
- Tags image for Harbor registry
- Logs in to Harbor using credentials
- Pushes image to Harbor
- Logs out after push

### 4. Trivy Scan
- Scans image with Trivy
- Fails build on HIGH or CRITICAL vulnerabilities
- Generates JSON report
- Archives report as build artifact

### 5. Generate SBOM
- Generates SPDX JSON SBOM
- Generates CycloneDX JSON SBOM
- Generates table format for quick view
- Archives all SBOMs as build artifacts

### 6. Sign Image
- Signs image with Cosign
- Adds build metadata as annotations
- Uses private key from Jenkins credentials
- Sets insecure skip verify for Harbor without TLS

### 7. Verify Signature
- Verifies image signature
- Uses public key from Jenkins credentials
- Ensures signature is valid
- Fails build if verification fails

### 8. Publish Artifacts
- Creates artifact summary
- Archives summary as build artifact
- Includes build metadata

## Corporate Certificate Handling

### DellRoot2018.cer

For corporate environments with DellRoot2018.cer, the certificate should be pre-installed on the Jenkins agent by system administrators. Do not attempt to install certificates in the pipeline.

**Pre-installation Steps (System Administrator):**

```bash
# ⚠️ ONE-TIME ADMINISTRATOR SETUP ONLY. Never execute inside Jenkins pipelines.
# Add certificate to system trust store (requires admin access)
sudo cp DellRoot2018.cer /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

**Pipeline Configuration:**

If the certificate is pre-installed, the tools will automatically use it. If using a custom certificate location:

```groovy
environment {
    // Set custom CA certificate path if not in system trust store
    SSL_CERT_FILE = "/path/to/DellRoot2018.cer"
    TRIVY_CA_CERT = "/path/to/DellRoot2018.cer"
}
```

**Important:** Never use `sudo` in Jenkins pipelines. Certificates must be pre-installed by system administrators.

### Harbor without TLS

For Harbor deployed without TLS (local development):

```groovy
environment {
    TRIVY_INSECURE = "true"
    COSIGN_INSECURE_SKIP_VERIFY = "true"
}
```

Note: This is acceptable for local development only. In production, Harbor should use TLS with valid certificates.

## Validation

### Test Pipeline

1. Create new pipeline job in Jenkins
2. Configure SCM to point to your repository
3. Set Script Path to `Jenkinsfile`
4. Configure required credentials
5. Run pipeline
6. Verify all stages complete successfully

### Validate Artifacts

After pipeline run, verify:
- Trivy report archived: `trivy-report-{BUILD_NUMBER}.json`
- SBOMs archived: `sbom-{BUILD_NUMBER}.spdx.json`, `sbom-{BUILD_NUMBER}.cyclonedx.json`
- Image signed and verified
- Artifact summary created

### Validate Image in Harbor

1. Access Harbor UI
2. Go to platform-prod project
3. Verify image appears
4. Check artifacts tab for SBOMs
5. Check artifacts tab for signatures

## Troubleshooting

### Podman Not Found

Ensure Podman is installed on Jenkins agent:
```bash
podman --version
```

### Harbor Login Fails

Verify Harbor is accessible via port-forward:
```bash
kubectl port-forward svc/harbor-portal -n harbor-system 30004:80
```

### Trivy Scan Fails

Check Trivy database is up to date:
```bash
trivy image --download-db-only
```

### Cosign Sign Fails

Verify key permissions:
```bash
chmod 600 cosign.key
```

### Certificate Errors

Set environment variables for corporate CA:
```bash
export SSL_CERT_FILE=/path/to/DellRoot2018.cer
export TRIVY_CA_CERT=/path/to/DellRoot2018.cer
```

## Best Practices

1. **Use Credentials**: Never hardcode passwords or keys
2. **Fail on Critical**: Always fail build on HIGH/CRITICAL vulnerabilities
3. **Archive Artifacts**: Archive all security reports and SBOMs
4. **Sign All Images**: Sign every image pushed to registry
5. **Verify Signatures**: Verify signatures before deployment
6. **Generate Multiple SBOMs**: Provide both SPDX and CycloneDX
7. **Add Metadata**: Include build metadata in signatures
8. **Clean Up**: Remove local images after push
9. **Monitor Failures**: Monitor pipeline failures for security issues
10. **Document Process**: Document pipeline configuration and credentials

## Additional Resources

- [Trivy Documentation](../trivy.md)
- [Syft Documentation](../syft.md)
- [Cosign Documentation](../cosign.md)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
