# Harbor and Jenkins Integration Guide

This guide explains how to integrate Harbor with Jenkins to enable automated image pushing from CI/CD pipelines.

## Prerequisites

- Harbor installed and accessible (Ticket 05)
- Jenkins installed and accessible (Ticket 03)
- Harbor project created
- Harbor admin or robot account credentials

## Integration Overview

The integration allows Jenkins to:
1. Build Docker images
2. Push images to Harbor registry
3. Use Harbor for image storage and distribution
4. Leverage Harbor's vulnerability scanning (Trivy)

## Step 1: Configure Harbor Credentials in Jenkins

### Option 1: Using Admin Credentials

1. Log in to Jenkins UI
2. Go to **Manage Jenkins** → **Credentials**
3. Click **System** → **Global credentials**
4. Click **Add Credentials**
5. Select **Username with password**
6. Enter:
   - **Username**: Your Harbor username (e.g., `admin`)
   - **Password**: Your Harbor password
7. Give it an ID (e.g., `harbor-credentials`)
8. Click **Create**

### Option 2: Using Robot Account (Recommended)

Robot accounts provide better security for automated access.

1. Create a robot account in Harbor (see Harbor Installation Guide)
2. Copy the robot account secret
3. In Jenkins, add credentials:
   - **Username**: Robot account name (e.g., `robot$platform-prod`)
   - **Password**: Robot account secret
4. Give it an ID (e.g., `harbor-robot-credentials`)
5. Click **Create**

## Step 2: Configure Docker Registry URL

In your Jenkins pipeline, you'll need to configure the Harbor registry URL.

**Harbor URL (via port-forward):**
```
localhost:30004
```

**Note:** Port-forward must be running for Harbor to be accessible:
```bash
kubectl port-forward svc/harbor-portal -n harbor-system 30004:80
```

**Example in Jenkinsfile:**
```groovy
environment {
    HARBOR_REGISTRY = "localhost:30004"
    HARBOR_PROJECT = "platform-prod"
    IMAGE_NAME = "sample-app"
    IMAGE_TAG = "${env.BUILD_NUMBER}"
}
```

## Step 3: Update Jenkins Pipeline

Here's a sample Jenkins pipeline stage for pushing to Harbor:

```groovy
stage('Push to Harbor') {
    steps {
        echo 'Pushing image to Harbor...'

        withCredentials([usernamePassword(
            credentialsId: 'harbor-credentials',
            usernameVariable: 'HARBOR_USER',
            passwordVariable: 'HARBOR_PASS'
        )]) {
            sh """
                # Log in to Harbor
                echo ${HARBOR_PASS} | docker login ${HARBOR_REGISTRY} -u ${HARBOR_USER} --password-stdin

                # Tag image for Harbor
                docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}

                # Push image to Harbor
                docker push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}

                # Log out
                docker logout ${HARBOR_REGISTRY}
            """
        }
    }
}
```

## Step 4: Configure Harbor in Docker

For Kind cluster, you may need to configure Docker to trust the Harbor registry.

### Add Harbor to Docker Insecure Registries

1. Edit Docker daemon configuration:
   ```bash
   sudo nano /etc/docker/daemon.json
   ```

2. Add Harbor to insecure registries:
   ```json
   {
     "insecure-registries": ["localhost:30004"]
   }
   ```

3. Restart Docker:
   ```bash
   sudo systemctl restart docker
   ```

**Note:** This is for development only. In production, use proper TLS certificates.

## Step 5: Test the Integration

### Manual Test

1. Create a test pipeline in Jenkins
2. Add the Harbor push stage
3. Run the pipeline
4. Verify in Harbor UI:
   - Go to your project
   - Click "Repositories"
   - Verify the image appears

### Automated Test

Update your Jenkinsfile to include Harbor push:

```groovy
pipeline {
    agent any

    environment {
        HARBOR_REGISTRY = "localhost:30004"
        HARBOR_PROJECT = "platform-prod"
        IMAGE_NAME = "sample-app"
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Build') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Push to Harbor') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'harbor-credentials',
                    usernameVariable: 'HARBOR_USER',
                    passwordVariable: 'HARBOR_PASS'
                )]) {
                    sh """
                        echo ${HARBOR_PASS} | docker login ${HARBOR_REGISTRY} -u ${HARBOR_USER} --password-stdin
                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker logout ${HARBOR_REGISTRY}
                    """
                }
            }
        }
    }
}
```

## Step 6: Configure Image Scanning (Optional)

Harbor includes Trivy for vulnerability scanning. You can configure Jenkins to wait for scan results.

### Enable Automatic Scanning in Harbor

1. Go to Harbor UI
2. Go to your project
3. Click "Configuration"
4. Enable "Automatically scan images on push"
5. Click "Save"

### Check Scan Results in Jenkins

```groovy
stage('Check Vulnerability Scan') {
    steps {
        echo 'Checking Harbor vulnerability scan results...'

        withCredentials([usernamePassword(
            credentialsId: 'harbor-credentials',
            usernameVariable: 'HARBOR_USER',
            passwordVariable: 'HARBOR_PASS'
        )]) {
            sh """
                # Get scan results from Harbor API
                SCAN_RESULT=\$(curl -s -u ${HARBOR_USER}:${HARBOR_PASS} \
                    http://${HARBOR_REGISTRY}/api/v2.0/projects/${HARBOR_PROJECT}/repositories/${IMAGE_NAME}/artifacts/${IMAGE_TAG}/scan)

                # Parse results (simplified)
                echo "Scan result: \$SCAN_RESULT"

                # Fail if critical vulnerabilities found
                # Add logic to parse and check severity
            """
        }
    }
}
```

## Step 7: Configure Retention Policy

Harbor can automatically clean up old images. Configure this in Harbor UI:

1. Go to your project
2. Click "Repositories"
3. Click "Retention Policy"
4. Create a rule to keep last N images
5. Set schedule (e.g., daily)

## Troubleshooting

### Docker Login Fails

1. Verify Harbor is accessible:
   ```bash
   curl http://localhost:30004/api/v2.0/systeminfo
   ```

2. Check credentials are correct
3. Verify Harbor project exists
4. Check user has push permissions

### Image Push Fails

1. Verify Docker is logged in:
   ```bash
   docker login localhost:30004
   ```

2. Check image tag format:
   ```
   localhost:30004/project-name/image-name:tag
   ```

3. Verify Harbor project exists
4. Check Harbor logs:
   ```bash
   kubectl logs -n harbor-system harbor-core-xxxxx -f
   ```

### Cannot Pull from Harbor

1. Verify project visibility (public vs private)
2. For private projects, ensure you're logged in:
   ```bash
   docker login localhost:30004
   ```

3. Check pull permissions in Harbor

### Jenkins Credential Issues

1. Verify credential ID matches what's used in pipeline
2. Test credentials manually:
   ```bash
   docker login localhost:30004 -u <username> -p <password>
   ```

3. Check Jenkins credential binding syntax

## Security Best Practices

1. **Use Robot Accounts**: Create dedicated robot accounts for Jenkins instead of using admin credentials
2. **Least Privilege**: Grant only necessary permissions (push/pull, not delete)
3. **Rotate Secrets**: Regularly rotate robot account secrets
4. **Use TLS**: In production, use proper TLS certificates instead of insecure registries
5. **Scan Images**: Enable automatic vulnerability scanning in Harbor
6. **Retention Policy**: Configure retention to limit storage usage
7. **Audit Logs**: Monitor Harbor audit logs for suspicious activity

## Next Steps

After Harbor and Jenkins are integrated:

1. Test the complete build and push workflow
2. Configure image scanning
3. Set up retention policies
4. Proceed to [Ticket 06: Sample Application](../issues/06-sample-application.md)

## Additional Resources

- [Harbor API Documentation](https://github.com/goharbor/harbor/blob/main/api/swagger.yaml)
- [Jenkins with Docker](https://www.jenkins.io/doc/book/pipeline/docker/)
- [Docker Registry Authentication](https://docs.docker.com/registry/spec/auth/)
