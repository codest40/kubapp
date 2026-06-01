# GitHub Observability System (sys_monitor/github)

# ------------------------------------------------------------
# 1. OVERVIEW
# ------------------------------------------------------------
The GitHub observability subsystem is an event-driven telemetry
pipeline that transforms raw GitHub webhook activity into real-time
operational intelligence.

It tracks engineering signals such as:

- Push activity
- Pull request flow
- Workflow execution health
- Job-level reliability
- Issue activity
- Release frequency
- Lead time for changes
- System anomalies and health scoring

At its core, the system converts:

GitHub activity → SLI/SLO signals → Prometheus metrics → Grafana dashboards


# ------------------------------------------------------------
# 2. HIGH-LEVEL ARCHITECTURE
# ------------------------------------------------------------
The system is composed of four main layers:


# ------------------------------------------------------------
# 2.1 EVENT INGESTION LAYER (FLASK WEBHOOK API)
# ------------------------------------------------------------
GitHub sends events via webhook to:

POST /webhook/github

Handled by:

src/routes/github.py

Responsibilities:

- Accept GitHub webhook payloads
- Normalize event types into internal canonical format
- Extract repository metadata
- Publish events into durable storage (SQLite event bus)

Key design decision:

Webhook ingestion is stateless.
All state is delegated to the event store.


# ------------------------------------------------------------
# 2.2 EVENT STORAGE LAYER (SQLITE EVENT BUS)
# ------------------------------------------------------------
File:
src/stream/event_bus.py

This is the source of truth for all GitHub events.

It implements:

- Append-only event persistence
- Replay capability (consume_all)
- Time-window querying (query_events_since)

Schema:

- event_type
- repo
- payload (JSON)
- timestamp

Design intent:

Treat GitHub activity as an event stream, not a request/response log.

This enables:

- SLO recomputation
- Historical replay
- Failure recovery in worker loops


# ------------------------------------------------------------
# 2.3 PROCESSING + SLO ENGINE (WORKER LOOP)
# ------------------------------------------------------------
File:
src/sre_engine/worker.py

This is the core intelligence loop of the system.

It runs continuously:

- start_http_server(8000)
- while True:
    - query_events_since(window)
    - compute metrics
    - update Prometheus
    - sleep(5s)


# A. EVENT CLASSIFICATION → METRICS
# ------------------------------------------------------------
GitHub events are converted into Prometheus counters:

- Pushes → github_push_total
- PRs → github_pr_total
- Issues → github_issue_total
- Workflow runs → github_workflow_run_total
- Jobs → github_workflow_job_total

This establishes raw observability signals.


# B. SLI COMPUTATION (CORE RELIABILITY SIGNAL)
# ------------------------------------------------------------
Workflow success is treated as the primary SLI:

sli = success_count / total_workflow_events

Derived metrics:

- Error rate = 1 - SLI
- Burn rate = error_rate / allowed_budget
- Remaining budget = 1 - SLO_TARGET - error_rate

This transforms CI/CD activity into SRE-grade reliability metrics.


# C. HEALTH SCORING LAYER
# ------------------------------------------------------------
File:
src/metrics/health.py

Outputs:

Health Score (0–100)

- base = sli * 100
- penalty applied when burn_rate > 1.0

Interpretation:

- High SLI → high health score
- Burn rate violation → score penalty


Anomaly Detection:

- sli < 0.90
- OR burn_rate > 1.0

Output:

- github_anomaly_flag


# ------------------------------------------------------------
# 2.4 METRICS EXPOSURE LAYER (PROMETHEUS)
# ------------------------------------------------------------
File:
src/app.py

Exposes:

/metrics

Using:

prometheus_client.generate_latest()

All counters and gauges become scrapeable Prometheus metrics.


# ------------------------------------------------------------
# 3. METRICS MODEL
# ------------------------------------------------------------
The system tracks multiple layers of GitHub behavior:


# ------------------------------------------------------------
# 3.1 DEVELOPER ACTIVITY METRICS
# ------------------------------------------------------------
- github_push_total
- github_pr_total
- github_issue_total

Represents engineering throughput.


# ------------------------------------------------------------
# 3.2 CI/CD RELIABILITY METRICS
# ------------------------------------------------------------
- github_workflow_run_total
- github_workflow_job_total
- github_workflow_duration_seconds

Represents delivery system health.


# ------------------------------------------------------------
# 3.3 RELEASE ENGINEERING METRICS
# ------------------------------------------------------------
- github_release_total
- github_change_lead_time_seconds

Represents DORA-style performance signals.


# ------------------------------------------------------------
# 3.4 SRE LAYER METRICS
# ------------------------------------------------------------
- slo_success_rate
- error_budget_burn_rate
- error_budget_remaining

Represents SLO governance signals.


# ------------------------------------------------------------
# 3.5 DERIVED INTELLIGENCE METRICS
# ------------------------------------------------------------
- github_health_score
- github_anomaly_flag

Represents higher-order system intelligence.


# ------------------------------------------------------------
# 4. EVENT NORMALIZATION STRATEGY
# ------------------------------------------------------------
Located in:

src/routes/github.py

All GitHub events are normalized into canonical types:

Workflow events:
- workflow_run_success
- workflow_run_failure

Job events:
- workflow_job_in_progress
- workflow_job_completed

Issues:
- issues_open
- issues_closed

Design principle:

Downstream systems never interpret raw GitHub semantics.

This ensures:

- SLO correctness
- Consistent aggregation
- Reduced event ambiguity


# ------------------------------------------------------------
# 5. GRAFANA OBSERVABILITY LAYER
# ------------------------------------------------------------
Dashboard:
observability/grafana/dashboards/github-overview.json


# 5.1 ENGINEERING ACTIVITY
# ------------------------------------------------------------
- Push event rate
- PR event rate
- Issue activity


# 5.2 CI/CD RELIABILITY
# ------------------------------------------------------------
- Workflow runs
- Workflow failures
- Success rate


# 5.3 PERFORMANCE ENGINEERING
# ------------------------------------------------------------
- Workflow duration
- Lead time for changes
- Deployment frequency


# 5.4 JOB-LEVEL OBSERVABILITY
# ------------------------------------------------------------
- Job execution rate
- Job failures
- Breakdown by job name


# 5.5 SYSTEM INTELLIGENCE
# ------------------------------------------------------------
- Health score gauge (0–100)
- Anomaly detection flag


# ------------------------------------------------------------
# 6. SLO DESIGN PHILOSOPHY
# ------------------------------------------------------------
This system treats GitHub as a production system, not just a
developer tool.

Primary SLO:

Workflow Success Rate ≥ 95%

Everything derives from this:

- error budget tracking
- burn rate calculation
- anomaly detection
- health scoring

Aligned with SRE principles (simplified burn-rate model).


# ------------------------------------------------------------
# 7. KEY DESIGN DECISIONS
# ------------------------------------------------------------


# 7.1 SQLITE AS EVENT STORE
# ------------------------------------------------------------
Pros:
- Simple replay model
- No external dependency
- Deterministic state reconstruction

Tradeoff:
- Not horizontally scalable


# 7.2 WORKER-BASED SLO COMPUTATION
# ------------------------------------------------------------
- Batch window: 5 minutes
- Continuous recomputation loop

Benefits:
- Simplicity
- Debuggability
- SLO reproducibility


# 7.3 PROMETHEUS AS SINGLE BACKEND
# ------------------------------------------------------------
No dual writing:

- logs
- tracing systems

Everything flows:

Prometheus → Grafana


# 7.4 EVENT-DRIVEN DESIGN
# ------------------------------------------------------------
Instead of polling GitHub APIs:

- System reacts to webhook events
- Builds internal event stream

Principle:

“GitHub is a telemetry source, not a dependency.”


# ------------------------------------------------------------
# 8. END-TO-END FLOW
# ------------------------------------------------------------
GitHub Webhook
      ↓
Flask Ingestion Layer
      ↓
SQLite Event Store
      ↓
Worker Loop (SLO Engine)
      ↓
Prometheus Metrics
      ↓
Grafana Dashboard


# ------------------------------------------------------------
# 9. SUMMARY
# ------------------------------------------------------------
The GitHub subsystem in sys_monitor is a mini observability platform that:

- Treats GitHub as an event stream
- Builds SRE-grade SLO computations
- Converts engineering activity into reliability signals
- Exposes everything via Prometheus
- Visualizes system health via Grafana

At its core, it transforms:

GitHub activity logs → production-grade reliability telemetry system
