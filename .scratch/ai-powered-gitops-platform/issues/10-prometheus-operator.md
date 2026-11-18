# 10: Prometheus Operator - Metrics Collection

**Status:** 🟡 READY TO START

**Objective:** Install Prometheus Operator to collect metrics from Kubernetes cluster and applications, enabling observability and alerting.

**Scope:**
- Install Prometheus Operator via Helm
- Configure Prometheus to scrape cluster metrics
- Set up ServiceMonitors for applications
- Configure metric retention
- Expose Prometheus UI
- Document metrics collection

**Acceptance Criteria:**
- [ ] Prometheus Operator is deployed
- [ ] Prometheus is collecting cluster metrics
- [ ] ServiceMonitors are configured for applications
- [ ] Prometheus UI is accessible
- [ ] Metrics are being scraped from pods
- [ ] Metric retention is configured
- [ ] Prometheus targets are healthy
- [ ] Metrics collection is documented

**Dependencies:**
- 01 (Foundation - Kind Cluster) - Cluster must be running
- 06 (Sample Application) - Application with metrics endpoint

**Deliverables:**
- `platform-core/config/prometheus/values.yaml` - Helm values for Prometheus
- `platform-core/config/prometheus/servicemonitors/*.yaml` - ServiceMonitor definitions
- `platform-core/scripts/install-prometheus.sh` - Installation script
- `platform-core/docs/prometheus/installation.md` - Installation guide
- `platform-core/docs/prometheus/servicemonitors.md` - ServiceMonitor guide
- `platform-core/docs/prometheus/metrics.md` - Metrics documentation

**Implementation Details:**

**Prometheus Configuration:**
- Namespace: `monitoring`
- Storage: PVC with 20Gi for metrics
- Service: NodePort on port 30005
- Retention: 15 days
- Scrape interval: 15s

**ServiceMonitors:**
- Kubernetes components (kubelet, kube-proxy, etc.)
- ArgoCD metrics
- Sample application metrics
- Jenkins metrics (if available)

**Metrics Format:**
- Application metrics in Prometheus format
- Labels for environment, app, version
- Custom metrics for business logic

**Validation Steps:**
1. Run `./platform-core/scripts/install-prometheus.sh`
2. Verify Prometheus pods: `kubectl get pods -n monitoring`
3. Access UI at http://localhost:30005
4. Check targets in Prometheus UI
5. Verify cluster metrics are being scraped
6. Apply ServiceMonitors for applications
7. Verify application metrics appear in Prometheus
8. Query metrics in Prometheus UI
9. Check metric retention configuration

**Definition of Done:**
- Prometheus Operator is deployed
- Cluster metrics are being collected
- Application metrics are being scraped
- Prometheus UI is accessible
- ServiceMonitors are configured
- Metrics collection is documented
- Developer can query metrics in Prometheus UI
