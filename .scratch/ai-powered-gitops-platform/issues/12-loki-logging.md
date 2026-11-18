# 12: Loki Logging - Log Aggregation

**Status:** 🟡 READY TO START

**Objective:** Install Loki for log aggregation and configure Promtail to collect logs from Kubernetes pods, enabling centralized log management.

**Scope:**
- Install Loki via Helm
- Install Promtail for log collection
- Configure log scraping from pods
- Set up log retention
- Integrate with Grafana for log viewing
- Document log management

**Acceptance Criteria:**
- [ ] Loki is deployed to Kind cluster
- [ ] Promtail is deployed and collecting logs
- [ ] Logs are being scraped from pods
- [ ] Loki datasource is configured in Grafana
- [ ] Logs are visible in Grafana
- [ ] Log retention is configured
- [ ] Log queries work in Grafana
- [ ] Logging is documented

**Dependencies:**
- 10 (Prometheus Operator) - Monitoring namespace exists
- 11 (Grafana Integration) - Grafana must be running

**Deliverables:**
- `platform-core/config/loki/values.yaml` - Helm values for Loki
- `platform-core/config/promtail/values.yaml` - Helm values for Promtail
- `platform-core/scripts/install-loki.sh` - Installation script
- `platform-core/docs/loki/installation.md` - Installation guide
- `platform-core/docs/loki/log-queries.md` - Log query guide
- `platform-core/docs/loki/grafana-integration.md` - Grafana integration guide

**Implementation Details:**

**Loki Configuration:**
- Namespace: `monitoring`
- Storage: PVC with 30Gi for logs
- Retention: 30 days
- Index: Periodic indexing

**Promtail Configuration:**
- Scrape logs from all pods
- Parse log formats (JSON, text)
- Add labels (namespace, pod, container)
- Filter logs by severity

**Grafana Integration:**
- Add Loki datasource
- Create log query panels
- Link metrics to logs (tempo integration if needed)

**Validation Steps:**
1. Run `./platform-core/scripts/install-loki.sh`
2. Verify Loki pods: `kubectl get pods -n monitoring`
3. Verify Promtail pods: `kubectl get pods -n monitoring`
4. Add Loki datasource in Grafana
5. Test datasource connection
6. Query logs in Grafana Explore
7. Verify logs from sample application appear
8. Test log filters and queries
9. Check log retention configuration

**Definition of Done:**
- Loki is deployed and collecting logs
- Promtail is scraping pod logs
- Logs are visible in Grafana
- Log queries work correctly
- Log retention is configured
- Logging is documented
- Developer can query and analyze logs
