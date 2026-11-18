# Harbor Installation Guide

This guide covers the installation and configuration of Harbor for the AI-Powered GitOps Platform.

## Prerequisites

- Kind cluster running (Ticket 01)
- ArgoCD installed (Ticket 02)
- Jenkins installed (Ticket 03)
- kubectl configured
- helm installed
- Docker installed (for testing image push)

## Installation

### Automated Installation

Run the installation script:

```bash
./platform-core/scripts/install-harbor.sh
```

This script will:
1. Check prerequisites
2. Add Harbor Helm repository
3. Create the harbor-system namespace
4. Install Harbor using Helm
5. Wait for Harbor to be ready
6. Display access information

### Manual Installation

If you prefer manual installation:

```bash
# Add Harbor Helm repository
helm repo add harbor https://helm.goharbor.io
helm repo update

# Create namespace
kubectl create namespace harbor-system

# Install Harbor
helm install harbor harbor/harbor \
  --namespace harbor-system \
  --values platform-core/config/harbor/values.yaml \
  --wait

# Wait for Harbor to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/instance=harbor \
  -n harbor-system \
  --timeout=600s
```

## Accessing Harbor

Harbor is deployed with ClusterIP service type. Use port-forwarding to access the UI.

**Start port-forward:**
```bash
kubectl port-forward svc/harbor-portal -n harbor-system 30004:80
```

**URL:** http://localhost:30004

**Initial Admin Password:**

Harbor generates a random password on first installation. Retrieve it with:

```bash
kubectl get secret harbor-core -n harbor-system -o jsonpath='{.data.HARBOR_ADMIN_PASSWORD}' | base64 -d
```

Username: `admin`
Password: (use the retrieved password)

⚠️ **IMPORTANT:** Change the password after first login!

## Post-Installation Configuration

### 1. Change Admin Password

1. Log in to Harbor UI at http://localhost:30004
2. Click on your username in the top right
3. Select "Change Password"
4. Enter current password and new password
5. Click "OK"

### 2. Create a Project

1. Click "New Project"
2. Enter project name (e.g., `platform-prod`)
3. Set visibility:
   - **Public**: Anyone can pull images
   - **Private**: Only authenticated users can pull/push (recommended)
4. Click "OK"

### 3. Configure Retention Policy

1. Go to your project
2. Click "Repositories"
3. Click "Retention Policy"
4. Click "New Rule"
5. Configure:
   - **Rule Name**: e.g., "Clean old images"
   - **Scope**: All repositories
   - **Tag Pattern**: `.*` (all tags)
   - **Retention**: Keep last 10 tags
   - **Schedule**: Daily
6. Click "Save"

### 4. Create Robot Account (Optional)

Robot accounts allow automated access without using admin credentials.

1. Go to your project
2. Click "Robot Accounts"
3. Click "New Robot Account"
4. Enter robot account name
5. Set expiration (optional)
6. Select permissions:
   - Push: ✅
   - Pull: ✅
   - Delete: ❌ (for safety)
7. Click "Add"
8. **IMPORTANT:** Copy the robot account secret immediately (won't be shown again)

## Verification

### Check Harbor Pod Status

```bash
kubectl get pods -n harbor-system
```

Expected output:
```
NAME                                  READY   STATUS    RESTARTS   AGE
harbor-core-xxxxxxxxx-xxxxx           1/1     Running   0          5m
harbor-database-xxxxxxxxx-xxxxx       1/1     Running   0          5m
harbor-jobservice-xxxxxxxxx-xxxxx     1/1     Running   0          5m
harbor-portal-xxxxxxxxx-xxxxx          1/1     Running   0          5m
harbor-registry-xxxxxxxxx-xxxxx       1/1     Running   0          5m
harbor-trivy-xxxxxxxxx-xxxxx           1/1     Running   0          5m
harbor-redis-xxxxxxxxx-xxxxx           1/1     Running   0          5m
```

### Check Harbor Service

```bash
kubectl get svc -n harbor-system
```

Expected output:
```
NAME            TYPE        PORT(S)             AGE
harbor-portal   ClusterIP   80/TCP              5m
harbor-core     ClusterIP   80/TCP,443/TCP,8443/TCP   5m
harbor-jobservice   ClusterIP   80/TCP          5m
harbor-registry   ClusterIP   5000/TCP,80/TCP   5m
```

### Check Harbor PVCs

```bash
kubectl get pvc -n harbor-system
```

Expected output:
```
NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES
data-harbor-redis-0     Bound    pvc-xxxx-xxxx-xxxx-xxxx                   2Gi        RWO
data-harbor-trivy-0     Bound    pvc-xxxx-xxxx-xxxx-xxxx                   5Gi        RWO
database-data-harbor-0  Bound    pvc-xxxx-xxxx-xxxx-xxxx                   5Gi        RWO
harbor-jobservice       Bound    pvc-xxxx-xxxx-xxxx-xxxx                   5Gi        RWO
harbor-registry         Bound    pvc-xxxx-xxxx-xxxx-xxxx                   20Gi        RWO
```

### Test Image Push

1. Start port-forward to Harbor registry:
   ```bash
   kubectl port-forward svc/harbor-portal -n harbor-system 30004:80
   ```

2. Log in to Harbor:
   ```bash
   docker login localhost:30004
   ```

3. Pull a test image:
   ```bash
   docker pull nginx:alpine
   ```

4. Tag the image for Harbor:
   ```bash
   docker tag nginx:alpine localhost:30004/platform-prod/nginx:alpine
   ```

5. Push the image:
   ```bash
   docker push localhost:30004/platform-prod/nginx:alpine
   ```

6. Verify in Harbor UI:
   - Go to your project
   - Click "Repositories"
   - Verify the image appears

**Note:** Keep the port-forward running in a separate terminal while testing.

## Troubleshooting

### Harbor Pods Not Starting

Check pod logs:
```bash
kubectl logs -n harbor-system <pod-name>
```

Common issues:
- Insufficient resources: Increase CPU/memory limits in values.yaml
- Storage issues: Check PVC status
- Image pull issues: Check image tag and registry access

### Cannot Access Harbor UI

1. Check service status:
   ```bash
   kubectl get svc -n harbor-system
   ```

2. Verify port-forward is running:
   ```bash
   kubectl port-forward svc/harbor-portal -n harbor-system 30004:80
   ```

3. Check Harbor pods are ready:
   ```bash
   kubectl get pods -n harbor-system
   ```

### Image Push Fails

1. Verify Harbor is accessible:
   ```bash
   curl http://localhost:30004/api/v2.0/systeminfo
   ```

2. Check Harbor logs:
   ```bash
   kubectl logs -n harbor-system harbor-core-xxxxx -f
   ```

3. Verify Docker is logged in:
   ```bash
   docker logout localhost:30004
   docker login localhost:30004
   ```

4. Check project permissions:
   - Verify you have push permissions for the project
   - Use robot account if available

### Cannot Retrieve Admin Password

If the secret doesn't exist:
```bash
kubectl get secrets -n harbor-system
```

If the secret exists but password is wrong:
- Harbor may have been reinstalled
- Check Harbor logs for initial password
- Reset password via Harbor UI if accessible

## Cleanup

To remove Harbor:

```bash
helm uninstall harbor -n harbor-system
kubectl delete namespace harbor-system
```

**Note:** PVCs will be retained due to `resourcePolicy: "keep"` in values.yaml. To delete PVCs:

```bash
kubectl delete pvc -n harbor-system -l app.kubernetes.io/instance=harbor
```

## Next Steps

After Harbor is installed and configured:

1. Configure Harbor credentials in Jenkins
2. Test image push from Jenkins pipeline
3. Configure retention policy
4. Proceed to [Ticket 06: Sample Application](../issues/06-sample-application.md)

## Additional Resources

- [Harbor Documentation](https://goharbor.io/docs/)
- [Harbor Helm Chart](https://github.com/goharbor/harbor-helm)
- [Harbor API Reference](https://github.com/goharbor/harbor/blob/main/api/swagger.yaml)
