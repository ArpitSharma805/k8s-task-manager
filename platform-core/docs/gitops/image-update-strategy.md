# Image Update Strategy for GitOps

This document describes strategies for updating container images in a GitOps workflow.

## Image Tag Strategies

### 1. Semantic Versioning (Recommended)

Use semantic versioning for image tags: `1.0.0`, `1.1.0`, `2.0.0`

**Pros:**
- Clear versioning
- Easy rollback
- Immutable tags

**Cons:**
- Requires manual tag updates
- Potential for tag reuse

**Usage:**
```yaml
image:
  tag: "1.0.0"
```

### 2. Build Number Tags

Use Jenkins build number as tag: `123`, `124`, `125`

**Pros:**
- Unique tags for each build
- Traceability to build
- Immutable

**Cons:**
- Less human-readable
- Need cleanup strategy

**Usage:**
```yaml
image:
  tag: "123"
```

### 3. SHA Digest Tags (Most Secure)

Use image digest: `sha256:abc123...`

**Pros:**
- Immutable
- Cryptographically verifiable
- No tag reuse

**Cons:**
- Hard to read
- Complex to manage

**Usage:**
```yaml
image:
  tag: "sha256:abc123..."
```

## Harbor Integration

### Update Image Tag in GitOps

To update the sample application image:

1. Build and push new image to Harbor
2. Update tag in `gitops/environments/dev/sample-app-values.yaml`:
   ```yaml
   image:
     tag: "1.1.0"
   ```
3. Commit and push to GitOps repository
4. ArgoCD automatically syncs deployment

### Harbor with Cluster-Internal DNS

For Jenkins agents running in-cluster:

```yaml
image:
  repository: harbor-core.harbor-system.svc.cluster.local/platform-prod/sample-app
  tag: "1.0.0"
```

For local validation with port-forward:

```yaml
image:
  repository: localhost:30004/platform-prod/sample-app
  tag: "1.0.0"
```

## Best Practices

1. **Use Semantic Versioning** for production
2. **Never reuse tags** - always use unique tags
3. **Document tag strategy** in team guidelines
4. **Implement tag cleanup** in Harbor retention policy
5. **Use digest tags** for critical deployments
6. **Automate tag updates** in Jenkins pipeline
7. **Test in dev first** before production
8. **Rollback strategy** documented
