# GitOps Observability System (sys_monitor/exporters/gitops)

# ------------------------------------------------------------
# 1. OVERVIEW
# ------------------------------------------------------------
The GitOps exporter is a Kubernetes-native observability agent
that continuously inspects the state of GitOps applications
inside an ArgoCD-based cluster and converts that state into
real-time convergence and drift metrics.

It provides visibility into:

- Application health
- Sync state (Git vs cluster drift)
- Degraded workloads
- Cluster-wide convergence score
- GitOps reliability posture

At its core, it answers:

"Is the cluster still aligned with Git?"


# ------------------------------------------------------------
# 2. HIGH-LEVEL ARCHITECTURE
# ------------------------------------------------------------
The system is built as a two-loop observability exporter:


# LOOP 1: HTTP METRICS SERVER
# ------------------------------------------------------------
- Exposes Prometheus metrics on /metrics (port 9105)
- Scraped by Prometheus


# LOOP 2: BACKGROUND COLLECTOR WORKER
# ------------------------------------------------------------
- Runs every 30 seconds
- Queries Kubernetes API
- Computes GitOps state metrics
- Updates Prometheus gauges


# FLOW
# ------------------------------------------------------------
Flask Server
   │
   ├── /metrics → Prometheus scrape endpoint
   │
Background Thread (every 30s)
   ↓
Kubernetes API → ArgoCD Applications
   ↓
State Aggregation Logic
   ↓
Prometheus Gauges
   ↓
Grafana Dashboard


# ------------------------------------------------------------
# 3. DATA SOURCE LAYER (KUBERNETES + ARGOCD)
# ------------------------------------------------------------

File:
src/k8s_client.py


# ------------------------------------------------------------
# 3.1 CLUSTER AUTHENTICATION
# ------------------------------------------------------------
Supports:

- Local mode (direct AWS session)
- Cross-account role assumption (STS AssumeRole)


# ------------------------------------------------------------
# 3.2 EKS TOKEN MANAGEMENT
# ------------------------------------------------------------
Implements:

- AWS EKS token generation (aws eks get-token)
- 12-minute safe caching window
- Prevents token regeneration overhead


# ------------------------------------------------------------
# 3.3 CIRCUIT BREAKER PROTECTION
# ------------------------------------------------------------
Protects against API instability:

- exponential backoff (10s → 300s cap)
- circuit open state
- failure tracking
- RBAC failure diagnostics

Design intent:

The exporter must fail safely, not destabilize the cluster API.


# ------------------------------------------------------------
# 3.4 KUBERNETES CLIENTS
# ------------------------------------------------------------
Exposes:

- CoreV1Api → nodes, cluster metadata
- CustomObjectsApi → ArgoCD CRDs


# ------------------------------------------------------------
# 4. GITOPS DATA COLLECTOR ENGINE
# ------------------------------------------------------------

File:
src/collector.py


# ------------------------------------------------------------
# 4.1 PRIMARY DATA SOURCE
# ------------------------------------------------------------
Queries:

group: argoproj.io
version: v1alpha1
plural: applications

This corresponds to ArgoCD Applications CRDs.


# ------------------------------------------------------------
# 4.2 STATE CLASSIFICATION LOGIC
# ------------------------------------------------------------

Applications are classified into:


# A. HEALTHY APPLICATIONS
# ------------------------------------------------------------
health.status == "Healthy"


# B. OUT-OF-SYNC APPLICATIONS
# ------------------------------------------------------------
sync.status != "Synced"


# C. DEGRADED APPLICATIONS
# ------------------------------------------------------------
health.status in ["Degraded", "Missing"]


# ------------------------------------------------------------
# 4.3 DERIVED SYSTEM METRICS
# ------------------------------------------------------------


# DRIFT RATIO
# ------------------------------------------------------------
out_of_sync / total_apps

Represents:
Git vs cluster divergence


# CONVERGENCE SCORE
# ------------------------------------------------------------
healthy / total_apps

Represents:
How aligned the cluster is with desired state


# ------------------------------------------------------------
# 5. METRICS MODEL (PROMETHEUS LAYER)
# ------------------------------------------------------------

File:
src/metrics.py


# ------------------------------------------------------------
# 5.1 FLEET STATE METRICS
# ------------------------------------------------------------
- gitops_app_total
- gitops_app_healthy_total
- gitops_app_out_of_sync_total
- gitops_app_degraded_total

Represents:

"What is the current state of the cluster?"


# ------------------------------------------------------------
# 5.2 SYSTEM STABILITY METRICS
# ------------------------------------------------------------
- gitops_drift_ratio
- gitops_convergence_score

Represents:

"How far are we from desired state?"


# ------------------------------------------------------------
# 6. EXECUTION MODEL
# ------------------------------------------------------------

File:
src/app.py


# TWO CONCURRENT PROCESSES
# ------------------------------------------------------------


# 1. FLASK METRICS SERVER
# ------------------------------------------------------------
GET /metrics → Prometheus scrape endpoint


# 2. BACKGROUND WORKER THREAD
# ------------------------------------------------------------
collect_metrics()
sleep(30s)


# Design outcome:

- low latency scraping
- continuous reconciliation
- no blocking between collection and serving


# ------------------------------------------------------------
# 7. GITOPS INTELLIGENCE MODEL
# ------------------------------------------------------------
This exporter does not expose raw Kubernetes data.

It builds operational intelligence layers:


# ------------------------------------------------------------
# 7.1 DRIFT DETECTION
# ------------------------------------------------------------
out_of_sync applications → drift_ratio

Answers:
"How many workloads are drifting from Git?"


# ------------------------------------------------------------
# 7.2 CONVERGENCE MEASUREMENT
# ------------------------------------------------------------
healthy / total → convergence_score

Answers:
"How stable is the GitOps system?"


# ------------------------------------------------------------
# 7.3 FLEET HEALTH AGGREGATION
# ------------------------------------------------------------
Combines:

- health status
- sync status
- degraded state

Into a unified reliability signal.


# ------------------------------------------------------------
# 8. GRAFANA OBSERVABILITY LAYER
# ------------------------------------------------------------

Dashboard:
observability/grafana/dashboards/gitops-overview.json


# ------------------------------------------------------------
# 8.1 FLEET OVERVIEW PANEL
# ------------------------------------------------------------
- Total GitOps applications
- Healthy applications
- Out-of-sync applications
- Degraded applications

Represents:
"What is running?"


# ------------------------------------------------------------
# 8.2 SYSTEM HEALTH PANEL
# ------------------------------------------------------------
- Convergence Score (gauge)

Represents:
"Is GitOps working correctly?"


# ------------------------------------------------------------
# 8.3 DRIFT CONTROL PANEL
# ------------------------------------------------------------
- Drift Ratio (gauge)

Represents:
"How broken is Git sync?"


# ------------------------------------------------------------
# 9. KEY DESIGN DECISIONS
# ------------------------------------------------------------


# 9.1 DIRECT KUBERNETES + ARGOCD CRD ACCESS
# ------------------------------------------------------------
Instead of ArgoCD API:

- Uses CustomObjectsApi (argoproj.io/v1alpha1)

Benefits:

- fewer dependencies
- higher observability fidelity


# ------------------------------------------------------------
# 9.2 BACKGROUND POLLING MODEL
# ------------------------------------------------------------
Instead of event streaming:

- full snapshot every 30 seconds

Tradeoff:

- simpler
- slightly higher latency
- deterministic state


# ------------------------------------------------------------
# 9.3 PROMETHEUS AS SINGLE SINK
# ------------------------------------------------------------
No intermediate storage:

- no DB
- no event store

Everything is scrape-based.


# ------------------------------------------------------------
# 9.4 CIRCUIT BREAKER KUBERNETES CLIENT
# ------------------------------------------------------------
Protects against:

- RBAC misconfigurations
- token expiry storms
- API rate limits


# ------------------------------------------------------------
# 10. END-TO-END FLOW
# ------------------------------------------------------------
ArgoCD Applications (K8s CRDs)
        ↓
Kubernetes API (CustomObjectsApi)
        ↓
Collector Engine (30s loop)
        ↓
Aggregation Logic (drift, convergence)
        ↓
Prometheus Gauges
        ↓
Grafana Dashboard


# ------------------------------------------------------------
# 11. SUMMARY
# ------------------------------------------------------------
The GitOps exporter in sys_monitor is a cluster-level
reconciliation observability system that:

- Continuously reads ArgoCD application state
- Computes drift and convergence metrics
- Exposes GitOps reliability signals via Prometheus
- Visualizes fleet health in Grafana

At a higher level:

It transforms Kubernetes + ArgoCD into a measurable reliability system,
not just a deployment system.
