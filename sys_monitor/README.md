# sys_monitor — SYSTEM DESIGN

## A GitOps Observability Platform that converts GitHub activity into real-time metrics, health scoring, anomaly detection, and Grafana dashboards.

------------------------------------------------------------
## OVERVIEW
------------------------------------------------------------
sys_monitor is a self-contained observability and system
intelligence subsystem designed to continuously inspect,
validate, and reason about the state of infrastructure and
runtime behavior.
It operates as a local control plane for system introspection,
combining:
- Infrastructure awareness (AWS test/prod simulation environments)
- Runtime analysis (codebase runners)
- Observability generation (metrics + evidence outputs)
- Security and drift evaluation
- Structural and architectural validation
Rather than acting as a passive monitoring tool, it behaves as
an active system auditor that produces structured evidence about
system health.
------------------------------------------------------------
CORE DESIGN PHILOSOPHY
------------------------------------------------------------
The system is built around three principles:
2.1 EVIDENCE OVER LOGS
------------------------------------------------------------
Instead of raw logs, sys_monitor produces structured outputs:
- JSON evidence files
- Metrics snapshots
- Validation reports
This enables deterministic reasoning about system state.
2.2 MULTI-DOMAIN OBSERVABILITY
------------------------------------------------------------
Observability is not limited to metrics.
It includes:
- infrastructure state
- security posture
- architectural boundaries
- runtime validation
- drift between desired and actual state
2.3 SELF-AUDITING SYSTEM DESIGN
------------------------------------------------------------
The system continuously evaluates itself through runners:
"The system is both the subject and the observer."
------------------------------------------------------------
ARCHITECTURE
------------------------------------------------------------
sys_monitor is structured into four tightly coupled subsystems:
------------------------------------------------------------
3.1 CLOUD LAYER (cloud/)
------------------------------------------------------------
This layer simulates and provisions infrastructure environments.
AWS ENVIRONMENT (cloud/aws)
Responsible for real or production-like infrastructure setup:
- EC2 provisioning
- VPC networking
- Route53 configuration
- TLS automation (start_letsencrypt.sh)
- Bootstrapping scripts (start.sh, create_env.sh)
This layer represents the execution environment where workloads run.
TEST ENVIRONMENT (cloud/test)
A simplified sandbox used for controlled validation:
- VPC setup (vpc.tf)
- Internet gateway and routing
- Public subnet configuration
- Security group definitions
- Single EC2 instance deployment
This environment is primarily used for safe infrastructure behavior testing.
------------------------------------------------------------
3.2 CODEBASE RUNNERS (codebase/runners/)
------------------------------------------------------------
This is the intelligence engine of sys_monitor.
Each runner is a domain-specific analyzer responsible for
producing structured system insights.
ARCHITECTURE.SH
------------------------------------------------------------
Detects architectural boundary violations
Ensures separation between system domains
DRIFT.SH
------------------------------------------------------------
Compares desired vs actual infrastructure state
Produces drift evidence snapshots
SECURITY.SH
------------------------------------------------------------
Detects plaintext secrets, tfvars exposure, insecure patterns
Produces security findings report
VALIDATION.SH
------------------------------------------------------------
Validates codebase structure and syntax consistency
Enforces internal policy rules
METRICS.SH
------------------------------------------------------------
Generates system telemetry signals
DISCOVERY.SH
------------------------------------------------------------
Builds full repository inventory map
Produces system-wide file and module index
Each runner produces structured outputs stored in:
codebase/evidence/
------------------------------------------------------------
3.3 EVIDENCE LAYER (codebase/evidence/)
------------------------------------------------------------
This is the core intelligence output system.
It stores structured system snapshots:
ARCHITECTURE.JSON
------------------------------------------------------------
- Architectural violations
- Coupling and boundary issues
- Structural integrity score
DRIFT.JSON
------------------------------------------------------------
- Infrastructure drift detection results
- Desired vs actual state comparison
SECURITY.JSON
------------------------------------------------------------
- Secret exposure detection
- Misconfiguration findings
- Security risk classification
VALIDATION.JSON
------------------------------------------------------------
- Code validation results
- Syntax and policy compliance
- File type and schema correctness
This layer transforms sys_monitor into a stateful reasoning system.
------------------------------------------------------------
3.4 SHARED LIBRARIES (codebase/lib/)
------------------------------------------------------------
Reusable utility layer used by all runners.
JSON.SH
------------------------------------------------------------
Provides structured JSON generation utilities:
- JSON escaping (json_escape)
- Array serialization (json_array)
- Boolean normalization (json_bool)
- Error/warning serialization
Ensures all runners produce consistent structured outputs.
------------------------------------------------------------
DATA FLOW ARCHITECTURE
------------------------------------------------------------
sys_monitor follows a pipeline-based evaluation model:
STEP 1: SYSTEM STATE COLLECTION
------------------------------------------------------------
- Cloud state (AWS/test infra)
- Repository structure
- Runtime environment signals
STEP 2: RUNNER EXECUTION
------------------------------------------------------------
Each domain runner executes independently:
- architecture analysis
- drift detection
- security scanning
- validation checks
- metrics generation
STEP 3: EVIDENCE GENERATION
------------------------------------------------------------
Each runner outputs structured JSON into:
codebase/evidence/
STEP 4: AGGREGATION
------------------------------------------------------------
Evidence files act as the source of truth for system state.
They are consumed by:
- dashboards (Grafana)
- alerting rules (Prometheus)
- operational scripts
------------------------------------------------------------
OBSERVABILITY MODEL
------------------------------------------------------------
sys_monitor uses a hybrid observability model:
METRICS LAYER
------------------------------------------------------------
- Prometheus metrics (metrics.prom)
- Time-series system signals
EVIDENCE LAYER
------------------------------------------------------------
- JSON-based structured system snapshots
- Human + machine readable audit trail
VISUALIZATION LAYER
------------------------------------------------------------
Grafana dashboards:
- codebase overview
- GitHub signals
- GitOps signals (exported context)
- system health trends
This creates a 3-layer observability stack:
- metrics (quantitative)
- evidence (structured truth)
- visualization (interpretation)
------------------------------------------------------------
SECURITY MODEL
------------------------------------------------------------
Security is continuously evaluated as part of system observability.
Detected patterns:
- plaintext tfvars files
- embedded credentials in scripts
- secret misplacement in Kubernetes manifests
- accidental credential exposure in automation scripts
Output:
All findings are recorded in:
codebase/evidence/security.json
Security is treated as:
a continuously observable system state, not a periodic audit task.
------------------------------------------------------------
CLOUD INTEGRATION MODEL
------------------------------------------------------------
sys_monitor interacts with infrastructure in two modes:
7.1 AWS PRODUCTION-LIKE LAYER
------------------------------------------------------------
- Realistic infrastructure provisioning
- Networking, routing, TLS, EC2
- Used for validating real-world behavior
7.2 TEST SIMULATION LAYER
------------------------------------------------------------
- Minimal VPC + EC2 setup
- Controlled environment for validation
- Safe experimentation zone
This separation ensures:
production behavior can be validated without risking real infrastructure.
------------------------------------------------------------
OPERATIONAL LAYER (SCRIPTS)
------------------------------------------------------------
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
