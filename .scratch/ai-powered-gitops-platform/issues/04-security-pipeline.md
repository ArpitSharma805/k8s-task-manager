# 04: Security Pipeline - Trivy, Syft, and Cosign Integration

**Status:** 🟡 FILES READY - MANUAL STEPS REQUIRED

**Objective:** Integrate supply chain security tools (Trivy, Syft, Cosign) into the Jenkins pipeline to scan images, generate SBOMs, and sign images before deployment.

**Scope:**
- Install Trivy for vulnerability scanning
- Install Syft for SBOM generation
- Install Cosign for image signing
- Create Jenkins pipeline stages for security checks
- Configure policy to fail builds on critical vulnerabilities
- Generate and store SBOMs
- Sign images with Cosign
- Integrate with Harbor registry
- Document corporate certificate handling

**Acceptance Criteria:**
- [ ] Trivy documentation completed
- [ ] Syft documentation completed
- [ ] Cosign documentation completed
- [ ] Jenkins integration documented
- [ ] Harbor integration documented
- [ ] Example pipeline created
- [ ] Corporate certificate strategy documented
- [ ] No hardcoded secrets
- [ ] Validation procedures included

**Dependencies:**
- 01 (Foundation - Kind Cluster) - ✅ COMPLETE
- 02 (GitOps Foundation - ArgoCD) - ✅ COMPLETE
- 03 (Jenkins Foundation) - ✅ COMPLETE
- 05 (Harbor Integration) - ✅ COMPLETE

**Deliverables:**
- `platform-core/scripts/install-security-tools.sh` - Security tools installation script
- `platform-core/docs/security/trivy.md` - Trivy documentation
- `platform-core/docs/security/syft.md` - Syft documentation
- `platform-core/docs/security/cosign.md` - Cosign documentation
- `platform-core/docs/security/pipeline-example.md` - Complete Jenkins pipeline example
- `platform-core/config/security/trivy-config.yaml` - Trivy configuration
- `platform-core/config/security/cosign-policy.md` - Cosign policy definition

**Implementation Details:**

**Trivy Configuration:**
- Image scanning workflow
- Harbor image scanning integration
- Filesystem scanning capability
- Severity thresholds: HIGH, CRITICAL
- Fail build on HIGH or CRITICAL findings
- Ignore policy examples
- Corporate CA guidance (DellRoot2018.cer)
- Harbor integration (insecure mode for local development)

**Syft Configuration:**
- Generate SPDX JSON format
- Generate CycloneDX JSON format
- Store SBOMs as Jenkins artifacts
- Harbor image support
- Local filesystem support
- Corporate CA guidance

**Cosign Configuration:**
- Key pair generation
- Harbor image signing
- Signature verification
- Public key distribution
- Key storage recommendations (Jenkins credentials, KMS)
- Jenkins integration
- Corporate CA guidance
- Certificate rotation process

**Jenkins Pipeline:**
1. Checkout source code
2. Build image with Podman
3. Push image to Harbor (cluster-internal: harbor-core.harbor-system.svc.cluster.local/platform-prod)
4. Trivy scan image (fail on HIGH/CRITICAL)
5. Generate SBOM using Syft (SPDX and CycloneDX)
6. Archive SBOM artifacts
7. Sign image with Cosign
8. Verify signature
9. Publish build artifacts

**Pipeline Requirements:**
- Use Harbor project: platform-prod
- Use cluster-internal Harbor registry: harbor-core.harbor-system.svc.cluster.local
- For local validation: use localhost:30004 with port-forward
- No hardcoded credentials (use Jenkins credentials)
- Use Jenkins credentials for Harbor and Cosign
- Fail on HIGH or CRITICAL vulnerabilities
- Produce CycloneDX and SPDX outputs

**Corporate Certificate Handling:**
- DellRoot2018.cer for corporate environments (pre-installed by system admin, not in pipeline)
- Harbor without TLS (local development)
- Jenkins certificate configuration (pre-installed by system admin)
- Trivy database downloads
- Cosign communication with HTTP registry (requires COSIGN_INSECURE_SKIP_VERIFY=true)
- Future certificate rotation process

**Validation Steps:**

**Local Validation (with port-forward):**
1. Start port-forward: `kubectl port-forward svc/harbor-portal -n harbor-system 30004:80`
2. Run `./platform-core/scripts/install-security-tools.sh`
3. Verify Trivy installation: `trivy --version`
4. Verify Syft installation: `syft --version`
5. Verify Cosign installation: `cosign version`
6. Validate Trivy scan: `trivy image --severity HIGH,CRITICAL --exit-code 1 --insecure localhost:30004/platform-prod/nginx:alpine`
7. Validate Syft SBOM: `syft localhost:30004/platform-prod/nginx:alpine -o cyclonedx-json=sbom.json`
8. Validate Cosign signing: `export COSIGN_INSECURE_SKIP_VERIFY=true && cosign sign --key cosign.key localhost:30004/platform-prod/nginx:alpine`
9. Validate Cosign verification: `export COSIGN_INSECURE_SKIP_VERIFY=true && cosign verify --key cosign.pub localhost:30004/platform-prod/nginx:alpine`

**Jenkins Agent Validation (cluster-internal):**
1. Verify Harbor is accessible from Jenkins agent: `podman login harbor-core.harbor-system.svc.cluster.local`
2. Validate Trivy scan: `trivy image --severity HIGH,CRITICAL --exit-code 1 --insecure harbor-core.harbor-system.svc.cluster.local/platform-prod/nginx:alpine`
3. Validate Syft SBOM: `syft harbor-core.harbor-system.svc.cluster.local/platform-prod/nginx:alpine -o cyclonedx-json=sbom.json`
4. Validate Cosign signing: `export COSIGN_INSECURE_SKIP_VERIFY=true && cosign sign --key cosign.key harbor-core.harbor-system.svc.cluster.local/platform-prod/nginx:alpine`
5. Validate Cosign verification: `export COSIGN_INSECURE_SKIP_VERIFY=true && cosign verify --key cosign.pub harbor-core.harbor-system.svc.cluster.local/platform-prod/nginx:alpine`

**Pipeline Configuration:**
10. Configure Jenkins credentials (Harbor, Cosign keys)
11. Create pipeline job using Jenkinsfile from pipeline-example.md
12. Run pipeline and verify all stages complete

**Definition of Done:**
- Security tools are installed and documented
- Jenkins pipeline includes security stages
- Critical vulnerabilities fail builds
- SBOMs are generated and stored
- Images are signed before deployment
- Security workflow is documented
- Corporate certificate strategy is documented
- Developer can integrate security checks into pipeline

---

## Implementation Status

**Files Created:**
- ✅ `platform-core/scripts/install-security-tools.sh` - Security tools installation script (executable)
- ✅ `platform-core/docs/security/trivy.md` - Comprehensive Trivy documentation
- ✅ `platform-core/docs/security/syft.md` - Comprehensive Syft documentation
- ✅ `platform-core/docs/security/cosign.md` - Comprehensive Cosign documentation
- ✅ `platform-core/docs/security/pipeline-example.md` - Complete Jenkins pipeline example
- ✅ `platform-core/config/security/trivy-config.yaml` - Trivy configuration file
- ✅ `platform-core/config/security/cosign-policy.md` - Cosign policy definition

**Manual Steps Required:**
1. Run installation script: `./platform-core/scripts/install-security-tools.sh`
2. Verify tool installations
3. Configure corporate CA if needed (DellRoot2018.cer)
4. Generate Cosign key pair: `cosign generate-key-pair`
5. Configure Jenkins credentials:
   - Harbor credentials
   - Cosign private key
   - Cosign public key
   - Cosign password
6. Create pipeline job using Jenkinsfile from pipeline-example.md
7. Run pipeline and verify all stages complete
8. Validate artifacts are archived
9. Validate image is signed in Harbor

**Notes:**
- Installation script installs tools locally (not in cluster)
- Tools work with Podman instead of Docker
- Harbor accessed via cluster-internal DNS for Jenkins agents (harbor-core.harbor-system.svc.cluster.local)
- Harbor accessed via port-forward for local validation (localhost:30004)
- Harbor deployed without TLS (local development)
- Corporate CA (DellRoot2018.cer) must be pre-installed by system administrators (not in pipeline)
- All sudo commands labeled as "ONE-TIME ADMINISTRATOR SETUP ONLY"
- Pipeline uses Jenkins credentials (no hardcoded secrets)
- Pipeline fails on HIGH/CRITICAL vulnerabilities
- SBOMs generated in both SPDX and CycloneDX formats (corrected Syft syntax: `-o format=file`)
- Images signed with Cosign before deployment
- Cosign requires COSIGN_INSECURE_SKIP_VERIFY=true for Harbor HTTP registry
- Certificate rotation process documented
- No sudo commands in Jenkins pipelines
- Documentation clearly separates local validation from Jenkins agent access
