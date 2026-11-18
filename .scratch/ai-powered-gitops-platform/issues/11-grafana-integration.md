# 11: Grafana Integration - Dashboards and Visualization

**Status:** 🟡 READY TO START

**Objective:** Install Grafana and create dashboards to visualize metrics from Prometheus, providing insights into cluster and application health.

**Scope:**
- Install Grafana via Helm
- Configure Grafana datasource (Prometheus)
- Create pre-built dashboards
- Import community dashboards
- Configure user authentication
- Document dashboard usage

**Acceptance Criteria:**
- [ ] Grafana is deployed to Kind cluster
- [ ] Grafana UI is accessible
- [ ] Prometheus datasource is configured
- [ ] Cluster overview dashboard is created
- [ ] Application dashboard is created
- [ ] Community dashboards are imported
- [ ] Admin credentials are documented
- [ ] Dashboards are documented

**Dependencies:**
- 10 (Prometheus Operator) - Prometheus must be running

**Deliverables:**
- `platform-core/config/grafana/values.yaml` - Helm values for Grafana
- `platform-core/config/grafana/dashboards/*.json` - Dashboard definitions
- `platform-core/config/grafana/datasources/*.yaml` - Datasource configurations
- `platform-core/scripts/install-grafana.sh` - Installation script
- `platform-core/docs/grafana/installation.md` - Installation guide
- `platform-core/docs/grafana/dashboards.md` - Dashboard documentation

**Implementation Details:**

**Grafana Configuration:**
- Namespace: `monitoring`
- Service: NodePort on port 30006
- Storage: PVC with 5Gi for dashboards
- Authentication: Admin credentials
- Anonymous access: Disabled

**Dashboards to Create:**
1. **Cluster Overview**: Node health, pod status, resource usage
2. **Application Metrics**: Request rate, error rate, latency
3. **ArgoCD Status**: Sync status, health status
4. **Jenkins Build Metrics**: Build duration, success rate

**Datasources:**
- Prometheus (primary)
- Loki (for logs, when installed)

**Validation Steps:**
1. Run `./platform-core/scripts/install-grafana.sh`
2. Verify Grafana pods: `kubectl get pods -n monitoring`
3. Access UI at http://localhost:30006
4. Login with admin credentials
5. Add Prometheus datasource
6. Test datasource connection
7. Import/create dashboards
8. Verify dashboards display data
9. Test dashboard queries
10. Save dashboards

**Definition of Done:**
- Grafana is deployed and accessible
- Prometheus datasource is configured
- Pre-built dashboards are available
- Dashboards display real-time metrics
- Dashboards are documented
- Developer can create custom dashboards
