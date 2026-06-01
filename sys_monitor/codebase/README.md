# KubApp SysMonitor (Codebase Observability Engine)


# ------------------------------------------------------------
# OVERVIEW
# ------------------------------------------------------------
KubApp SysMonitor is a codebase observability and governance
engine that treats a software repository as a first-class
operational system.

It continuously:

- scans the repository
- builds a canonical inventory
- evaluates structural and security health
- detects drift
- exports all signals as Prometheus metrics

for visualization in Grafana.

In simple terms:

It turns your Git repository into a self-monitoring system
with SRE-style insights.


# ------------------------------------------------------------
# ARCHITECTURE
# ------------------------------------------------------------
The system is built as a multi-stage pipeline:


runner.sh
   ├── discovery.sh        → Builds canonical inventory (source of truth)
   ├── drift.sh            → Detects divergence from expected structure
   ├── architecture.sh     → Evaluates system design rules & scoring
   ├── security.sh         → Detects secrets, keys, misconfigurations
   ├── validation.sh       → Validates syntax & correctness of files
   └── metrics.sh          → Exports Prometheus metrics


Each stage writes structured JSON evidence into:

/evidence/

Which is then consumed by downstream stages.


# ------------------------------------------------------------
# KEY DESIGN PRINCIPLES
# ------------------------------------------------------------


# 1. INVENTORY AS SOURCE OF TRUTH
# ------------------------------------------------------------
All analysis is based on a single generated file:

evidence/inventory.json

No engine independently re-discovers filesystem state
(except validation checks).


# 2. EVIDENCE-BASED OUTPUTS
# ------------------------------------------------------------
Every module emits structured JSON:

- findings
- errors
- warnings
- summaries

This ensures:

- reproducibility
- traceability
- deterministic debugging


# 3. PIPELINE ISOLATION
# ------------------------------------------------------------
Each engine is independent:

- discovery builds state
- other modules consume state only
- metrics layer aggregates results

No cross-contamination of logic.


# 4. OBSERVABILITY FIRST DESIGN
# ------------------------------------------------------------
Every scan produces Prometheus metrics:

- module health
- findings counts
- critical/warning/error breakdowns
- platform health score


# ------------------------------------------------------------
# MODULES
# ------------------------------------------------------------


# ------------------------------------------------------------
# DISCOVERY ENGINE
# ------------------------------------------------------------
Builds complete repository inventory:

Includes:

- Terraform roots/modules
- Shell scripts
- Kubernetes manifests
- Helm charts
- Dockerfiles
- Workflows
- Secrets
- Documentation

Output:

evidence/inventory.json


# ------------------------------------------------------------
# DRIFT ENGINE
# ------------------------------------------------------------
Detects inconsistencies between:

- inventory vs filesystem
- missing files
- orphaned files
- missing Terraform structures

Ensures repository integrity.


# ------------------------------------------------------------
# ARCHITECTURE ENGINE
# ------------------------------------------------------------
Evaluates system design rules:

- boundary violation detection (sys_monitor isolation)
- script duplication detection
- infra coupling detection
- workflow imbalance scoring

Outputs:

- architecture_score (0–100)
- structured findings


# ------------------------------------------------------------
# SECURITY ENGINE
# ------------------------------------------------------------
Performs repository security scanning:

- secret file detection
- plaintext credentials
- private key detection
- encrypted tfvars validation
- gitignore misconfigurations
- GitOps secret boundary rules

Detects:

- critical vulnerabilities
- misconfigured secrets
- exposed credentials


# ------------------------------------------------------------
# VALIDATION ENGINE
# ------------------------------------------------------------
Validates correctness of files:

- Bash syntax checks
- Python compilation checks
- JS/TS validation
- YAML/JSON validation
- Terraform formatting
- Helm template rendering
- Dockerfile sanity checks

Also enforces:

- whitelist-based file policy
- strict file classification rules


# ------------------------------------------------------------
# METRICS ENGINE
# ------------------------------------------------------------
Converts evidence into Prometheus metrics:

Key metrics:

- kubapp_platform_health
- kubapp_module_score
- kubapp_module_status
- kubapp_findings_total
- kubapp_critical_total
- kubapp_warning_total
- kubapp_error_total
- kubapp_total_files
- kubapp_total_shell_scripts
- kubapp_total_terraform_roots


# ------------------------------------------------------------
# WEB UI (FLASK APP)
# ------------------------------------------------------------
A lightweight Flask service exposes:


Endpoints:

/        → Dashboard UI
/health  → Service health check
/metrics → Prometheus metrics endpoint


# ------------------------------------------------------------
# GRAFANA DASHBOARD
# ------------------------------------------------------------
Located at:

observability/grafana/dashboards/codebase-overview.json

Visualizes:

- platform health (gauge)
- module health scores
- findings trends
- security violations
- drift issues
- inventory statistics
- scan freshness


# ------------------------------------------------------------
# RUNNING THE PIPELINE
# ------------------------------------------------------------
Execute full observability pipeline:

./runners/runner.sh


This runs:

- discovery
- drift analysis
- architecture checks
- security scanning
- validation
- metrics export


# ------------------------------------------------------------
# OUTPUT ARTIFACTS
# ------------------------------------------------------------
All outputs stored in:

/evidence


Example artifacts:

- inventory.json
- drift.json
- architecture.json
- security.json
- validation.json
- metrics.prom


# ------------------------------------------------------------
# PLATFORM HEALTH MODEL
# ------------------------------------------------------------
Overall system health is computed as:

platform_health = average(module_scores)


Scoring model:

- critical findings → high penalty
- warning findings → moderate penalty
- clean modules → full score


# ------------------------------------------------------------
# KEY INSIGHTS
# ------------------------------------------------------------
This system demonstrates:

- GitOps-style introspection of a codebase
- SRE-style observability applied to static systems
- Structured evidence generation per subsystem
- Metrics-first engineering visibility model


# ------------------------------------------------------------
# SECURITY MODEL
# ------------------------------------------------------------
Security scanning includes:

- secret detection (regex + heuristics)
- private key detection
- tfvars encryption enforcement
- GitOps secret boundary validation


# ------------------------------------------------------------
# WHY THIS PROJECT MATTERS
# ------------------------------------------------------------
This is not just a script collection.

It is:

A self-observing codebase that behaves like a production system.

It models real-world platform engineering concepts:

- telemetry pipelines
- reconciliation loops
- drift detection
- health scoring
- observability layers
