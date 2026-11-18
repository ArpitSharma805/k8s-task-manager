# Jenkins Installation Guide

This guide covers the installation and configuration of Jenkins for the AI-Powered GitOps Platform.

## Prerequisites

- Kind cluster running (Ticket 01)
- ArgoCD installed (Ticket 02)
- kubectl configured
- helm installed
- Docker installed (for Jenkins agents)

## Installation

### Automated Installation

Run the installation script:

```bash
./platform-core/scripts/install-jenkins.sh
```

This script will:
1. Check prerequisites
2. Add Jenkins Helm repository
3. Create the jenkins namespace
4. Install Jenkins using Helm
5. Wait for Jenkins to be ready
6. Display access information

### Manual Installation

If you prefer manual installation:

```bash
# Add Jenkins Helm repository
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Create namespace
kubectl create namespace jenkins

# Install Jenkins
helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --values platform-core/config/jenkins/values.yaml \
  --wait

# Wait for Jenkins to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/component=jenkins-master \
  -n jenkins \
  --timeout=300s
```

## Accessing Jenkins

Jenkins is exposed via NodePort on port 30003.

**URL:** http://localhost:30003

**Initial Admin Password:**

The initial admin password is auto-generated. Retrieve it with:

```bash
kubectl exec -n jenkins sts/jenkins -c jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Username: `admin`
Password: (use the retrieved password)

⚠️ **IMPORTANT:** Change the password after first login!

## Post-Installation Configuration

### 1. Install Additional Plugins

After logging in, install any additional plugins needed:

1. Go to **Manage Jenkins** → **Plugins**
2. Click **Available Plugins**
3. Search for and install:
   - Kubernetes CLI (kubectl)
   - Pipeline Utility Steps
   - HTTP Request Plugin
   - Build User Vars Plugin

### 2. Configure GitHub Credentials

1. Go to **Manage Jenkins** → **Credentials**
2. Click **System** → **Global credentials**
3. Click **Add Credentials**
4. Select **Username with password**
5. Enter your GitHub username and personal access token
6. Give it an ID (e.g., `github-credentials`)
7. Click **Create**

### 3. Configure Kubernetes Cloud

1. Go to **Manage Jenkins** → **Manage Nodes and Clouds**
2. Click **Configure Clouds**
3. Add a new cloud of type **Kubernetes**
4. Configure:
   - Kubernetes URL: `https://kubernetes.default.svc`
   - Jenkins URL: `http://jenkins.jenkins.svc.cluster.local:8080`
   - Kubernetes Namespace: `jenkins`
5. Click **Save**

### 4. Set Up GitHub Webhook (Optional for Ticket 03)

Webhook configuration is optional for Ticket 03 validation. Manual build triggers using "Build Now" in Jenkins are sufficient for initial validation.

See [Webhook Setup Guide](./webhook-setup.md) for detailed instructions when ready to configure webhooks.

## Verification

### Check Jenkins Pod Status

```bash
kubectl get pods -n jenkins
```

Expected output:
```
NAME                   READY   STATUS    RESTARTS   AGE
jenkins-xxxxxxxxx-xxxxx   1/1     Running   0          5m
```

### Check Jenkins Service

```bash
kubectl get svc -n jenkins
```

Expected output:
```
NAME      TYPE       PORT(S)          AGE
jenkins   NodePort   8080:30003/TCP   5m
```

### Check Jenkins Logs

```bash
kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller -f
```

### Access Jenkins UI

Open http://localhost:30003 in your browser and verify you can log in.

### Test Pipeline with Jenkinsfile-test

For Ticket 03 validation, use the simple test pipeline:

1. Create a new Pipeline job in Jenkins
2. Configure:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your GitHub repository URL
   - **Credentials**: Your GitHub credentials
   - **Branch**: `*/main`
   - **Script Path**: `platform-core/config/jenkins/Jenkinsfile-test`
3. Click **Save**
4. Click **Build Now**
5. Verify the pipeline executes successfully
6. Check the console output for:
   - "Hello from Jenkins!"
   - Build number
   - Git branch and commit
   - Environment variables

**Ticket 03 validates:**
- Jenkins deployment
- GitHub connectivity
- Pipeline execution

**Note:** Security scanning (Trivy, Syft, Cosign) and Harbor integration are implemented in Ticket 04.

## Troubleshooting

### Jenkins Pod Not Starting

Check pod logs:
```bash
kubectl logs -n jenkins <pod-name>
```

Common issues:
- Insufficient resources: Increase CPU/memory limits in values.yaml
- Storage issues: Check PVC status
- Image pull issues: Check image tag and registry access

### Cannot Access Jenkins UI

1. Check service status:
   ```bash
   kubectl get svc jenkins -n jenkins
   ```

2. Check NodePort is configured:
   ```bash
   kubectl describe svc jenkins -n jenkins
   ```

3. Port-forward to test:
   ```bash
   kubectl port-forward -n jenkins svc/jenkins 8080:8080
   ```

### Plugin Installation Fails

1. Check Jenkins logs for errors
2. Try installing plugins manually from UI
3. Check network connectivity to plugin repository

### GitHub Webhook Not Triggering

1. Verify webhook URL is correct
2. Check Jenkins is accessible from GitHub
3. Check Jenkins logs for webhook errors
4. Verify webhook secret matches

## Cleanup

To remove Jenkins:

```bash
helm uninstall jenkins -n jenkins
kubectl delete namespace jenkins
```

## Next Steps

After Jenkins is installed and configured:

1. Retrieve initial admin password
2. Create your first pipeline job using Jenkinsfile-test
3. Run manual build to verify pipeline execution
4. Configure GitHub webhook (optional, can be deferred)
5. Test the pipeline
6. Proceed to [Ticket 04: Security Pipeline](../issues/04-security-pipeline.md)

**Ticket 03 validates:**
- Jenkins deployment
- Jenkins UI accessibility
- Git clone capability
- Manual pipeline execution

Webhook validation can be deferred until GitOps automation work (Ticket 08).

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Helm Chart](https://github.com/jenkinsci/helm-charts)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
