# sys_monitor — SYSTEM DESIGN

## A GitOps Observability Platform that converts GitHub activity into real-time metrics, health scoring, anomaly detection, and Grafana dashboards.

# ------------------------------------------------------------
# OVERVIEW
# ------------------------------------------------------------
sys_monitor is a self-contained observability and system intelligence subsystem designed to continuously inspect, validate, and reason about the state of infrastructure and runtime behavior.

It operates as a local control plane for system introspection, combining:

- Infrastructure awareness (AWS test/prod simulation environments)
- Runtime analysis (codebase runners)
- Observability generation (metrics + evidence outputs)
- Security and drift evaluation
- Structural and architectural validation

Rather than acting as a passive monitoring tool, it behaves as an active system auditor that produces structured evidence about system health.

# ------------------------------------------------------------
# CORE DESIGN PHILOSOPHY
# ------------------------------------------------------------

## 2.1 Evidence over Logs
Instead of raw logs, sys_monitor produces structured outputs:

- JSON evidence files
- Metrics snapshots
- Validation reports

This enables deterministic reasoning about system state.

## 2.2 Multi-Domain Observability
Observability is not limited to metrics.

It includes:

- infrastructure state
- security posture
- architectural boundaries
- runtime validation
- drift between desired and actual state

## 2.3 Self-Auditing System Design
The system continuously evaluates itself through runners:

"The system is both the subject and the observer."

# ------------------------------------------------------------
# ARCHITECTURE
# ------------------------------------------------------------

sys_monitor is structured into four tightly coupled subsystems:

# ------------------------------------------------------------
# 3.1 Cloud Layer (cloud/)
# ------------------------------------------------------------
This layer simulates and provisions infrastructure environments.

AWS Environment (cloud/aws):

- EC2 provisioning
- VPC networking
- Route53 configuration
- TLS automation (start_letsencrypt.sh)
- Bootstrapping scripts (start.sh, create_env.sh)

This layer represents the execution environment where workloads run.

Test Environment (cloud/test):

- VPC setup (vpc.tf)
- Internet gateway and routing
- Public subnet configuration
- Security group definitions
- Single EC2 instance deployment

This is primarily used for safe infrastructure behavior testing.

# ------------------------------------------------------------
# 3.2 Codebase Runners (codebase/runners/)
# ------------------------------------------------------------
This is the intelligence engine of sys_monitor.

Each runner is a domain-specific analyzer responsible for producing structured system insights.

architecture.sh
- Detects architectural boundary violations
- Ensures separation between system domains

drift.sh
- Compares desired vs actual infrastructure state
- Produces drift evidence snapshots

security.sh
- Detects plaintext secrets, tfvars exposure, insecure patterns
- Produces security findings report

validation.sh
- Validates codebase structure and syntax consistency
- Enforces internal policy rules

metrics.sh
- Generates system telemetry signals

discovery.sh
- Builds full repository inventory map
- Produces system-wide file and module index

Each runner produces structured outputs stored in:

codebase/evidence/

# ------------------------------------------------------------
# 3.3 Evidence Layer (codebase/evidence/)
# ------------------------------------------------------------
This is the core intelligence output system.

It stores structured system snapshots:

architecture.json
- Architectural violations
- Coupling and boundary issues
- Structural integrity score

drift.json
- Infrastructure drift detection results
- Desired vs actual state comparison

security.json
- Secret exposure detection
- Misconfiguration findings
- Security risk classification

validation.json
- Code validation results
- Syntax and policy compliance
- File type and schema correctness

This layer transforms sys_monitor into a stateful reasoning system.

# ------------------------------------------------------------
# 3.4 Shared Libraries (codebase/lib/)
# ------------------------------------------------------------
Reusable utility layer used by all runners.

json.sh
- JSON escaping (json_escape)
- Array serialization (json_array)
- Boolean normalization (json_bool)
- Error/warning serialization

Ensures all runners produce consistent structured outputs.

# ------------------------------------------------------------
# DATA FLOW ARCHITECTURE
# ------------------------------------------------------------

Step 1: System State Collection
- Cloud state (AWS/test infra)
- Repository structure
- Runtime environment signals

Step 2: Runner Execution
- architecture analysis
- drift detection
- security scanning
- validation checks
- metrics generation

Step 3: Evidence Generation
- Outputs written to codebase/evidence/

Step 4: Aggregation
Evidence files become the system of record and are consumed by:

- dashboards (Grafana)
- alerting rules (Prometheus)
- operational scripts

# ------------------------------------------------------------
# OBSERVABILITY MODEL
# ------------------------------------------------------------

Metrics Layer
- Prometheus metrics (metrics.prom)
- Time-series system signals

Evidence Layer
- JSON-based structured system snapshots
- Human + machine readable audit trail

Visualization Layer
- Grafana dashboards:
  - codebase overview
  - GitHub signals
  - GitOps signals
  - system health trends

Resulting stack:

- metrics (quantitative)
- evidence (structured truth)
- visualization (interpretation)

# ------------------------------------------------------------
# SECURITY MODEL
# ------------------------------------------------------------
Security is continuously evaluated as part of system observability.

Detected patterns:

- plaintext tfvars files
- embedded credentials in scripts
- secret misplacement in Kubernetes manifests
- accidental credential exposure in automation scripts

Output:

codebase/evidence/security.json

Security is treated as a continuously observable system state, not a periodic audit task.

# ------------------------------------------------------------
# CLOUD INTEGRATION MODEL
# ------------------------------------------------------------

7.1 AWS Production-like Layer
- Realistic infrastructure provisioning
- Networking, routing, TLS, EC2
- Used for validating real-world behavior

7.2 Test Simulation Layer
- Minimal VPC + EC2 setup
- Controlled environment for validation
- Safe experimentation zone

This separation ensures production behavior can be validated without risking real infrastructure.

# ------------------------------------------------------------
# OPERATIONAL LAYER (SCRIPTS)
# ------------------------------------------------------------
Shell scripts act as lightweight orchestration tools:

- cluster lifecycle management
- environment setup and teardown
- validation execution
- cleanup operations
- Terraform execution wrappers

This avoids heavy orchestration systems while maintaining:

- reproducibility
- automation
- operational control

