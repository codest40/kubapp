# RE ENGINE — RELIABILITY INTELLIGENCE LAYER (ssre_engine)


# ------------------------------------------------------------
# 1. OVERVIEW — WHAT THIS SUBSYSTEM ACTUALLY DOES
# ------------------------------------------------------------
The SRE Engine is the decision-making layer of sys_monitor.

While other components observe systems (GitHub, GitOps, Kubernetes),
this engine answers:

“Is the system healthy in SRE terms, and is it trending toward failure?”

It transforms raw event data into:

- SLO compliance signals
- error budget consumption
- burn rate analysis
- anomaly detection
- health scoring (0–100)

In system design terms:

This is a streaming SRE evaluation engine over an event-sourced reliability model


# ------------------------------------------------------------
# 2. WHERE IT SITS IN THE ARCHITECTURE
# ------------------------------------------------------------
The SRE engine is a parallel consumer of system truth, not a scraper.

It consumes the same event backbone used by GitHub ingestion:

GitHub Exporter
      │
      ▼
SQLite Event Store (append-only truth)
      │
      ├──────────────────────────────┐
      ▼                              ▼
GitOps Exporter                SRE Engine Worker
(Kubernetes state)            (SLO computation)
                                     │
                                     ▼
                              Prometheus metrics
                                     │
                                     ▼
                                  Grafana


Key idea:

GitOps tells you “what changed in infrastructure”

SRE engine tells you “what that change means for reliability”


# ------------------------------------------------------------
# 3. CORE DESIGN PHILOSOPHY
# ------------------------------------------------------------
The engine is built on three principles:


# 3.1 EVENT SOURCING OVER STATE TRACKING
# ------------------------------------------------------------
Instead of querying live systems, it replays events from SQLite:

- deterministic
- replayable
- debuggable
- time-window based


# 3.2 WINDOWED COMPUTATION MODEL
# ------------------------------------------------------------
All SLO logic is computed over a rolling window:

WINDOW_SECONDS = 300  # 5 minutes

This creates:

- near real-time observability
- stable SLO evaluation (not noisy instant signals)


# 3.3 SEPARATION OF CONCERNS
# ------------------------------------------------------------
- ingestion = GitHub exporter
- storage = SQLite event log
- computation = SRE engine
- visualization = Grafana

No mixed responsibilities.


# ------------------------------------------------------------
# 4. EVENT MODEL — THE FOUNDATION
# ------------------------------------------------------------
Events are normalized into a canonical structure:

{
  "event_type": "...",
  "repo": "...",
  "payload": {...},
  "timestamp": ...
}


SQLite Schema:

events (
  id INTEGER PRIMARY KEY,
  event_type TEXT,
  repo TEXT,
  payload TEXT,
  timestamp REAL
)


# WHY SQLITE?
# ------------------------------------------------------------
This is intentional:

- zero infra overhead (no Kafka/Redis required)
- strong consistency
- replay capability
- perfect for local + portfolio-grade SRE simulation


# ------------------------------------------------------------
# 5. EVENT INGESTION LAYER (stream/event_bus.py)
# ------------------------------------------------------------


# 5.1 APPEND-ONLY MODEL
# ------------------------------------------------------------
def publish(event):
    INSERT INTO events ...

System property:

- immutable event log (append-only truth)


# 5.2 QUERY MODEL (TIME WINDOWING)
# ------------------------------------------------------------
def query_events_since(since_ts):

Used for:

- sliding window SLO computation
- burst detection
- anomaly correlation


# ------------------------------------------------------------
# 6. SLO ENGINE CORE LOGIC
# ------------------------------------------------------------


# 6.1 SUCCESS RATE (SLI COMPUTATION)
# ------------------------------------------------------------
sli = success_count / total_events

If no events exist:

sli = 1.0  # optimistic default


# 6.2 ERROR RATE
# ------------------------------------------------------------
error_rate = 1 - sli


# 6.3 ERROR BUDGET MODEL
# ------------------------------------------------------------
SLO_TARGET = 0.95
ERROR_BUDGET = 1.0 - SLO_TARGET

Meaning:

- SLO target = 95% success
- error budget = 5% allowable failure


# 6.4 BURN RATE (CORE SRE SIGNAL)
# ------------------------------------------------------------
burn_rate = error_rate / ERROR_BUDGET


Interpretation:

Burn Rate    Meaning
------------------------------------------------
< 1.0        safe
= 1.0        consuming budget exactly
> 1.0        burning budget too fast


This aligns with Google-style SRE principles.


# ------------------------------------------------------------
# 7. WORKER ENGINE — RUNTIME LOOP
# ------------------------------------------------------------
The engine runs continuously:

while True:
    events = query_events_since(now - WINDOW_SECONDS)

Cycle time: 5 seconds

System behavior:

- mini streaming analytics engine
- sliding window computation model


# ------------------------------------------------------------
# 8. EVENT PROCESSING PIPELINE
# ------------------------------------------------------------


# 8.1 PUSH / PR / ISSUE EVENTS
# ------------------------------------------------------------
- counted for activity metrics
- NOT SLO-critical signals


# 8.2 WORKFLOW EVENTS (SLO-CRITICAL)
# ------------------------------------------------------------
workflow_run_success → success = 1
workflow_run_failure → success = 0

These define:

- system reliability signal (SLI source of truth)


# 8.3 WORKFLOW JOBS (GRANULAR OBSERVABILITY)
# ------------------------------------------------------------
Tracked:

- job name
- status
- conclusion

Used for:

- pipeline failure debugging
- flaky stage detection


# ------------------------------------------------------------
# 9. SLO COMPUTATION LAYER
# ------------------------------------------------------------
sli = compute_sli(workflow_events)
error_rate = 1 - sli
burn_rate = error_rate / ERROR_BUDGET
remaining_budget = ERROR_BUDGET - error_rate

Result:

Full SRE state snapshot per evaluation cycle


# ------------------------------------------------------------
# 10. HEALTH SCORING MODEL
# ------------------------------------------------------------
health = compute_health_score(sli, burn_rate)

Logic:

- base = SLI × 100
- penalty applied if burn_rate > 1.0
- clamped between 0–100


Interpretation:

Health Score     Meaning
----------------------------------------
90–100           stable system
70–89            warning zone
<70              reliability degradation


# ------------------------------------------------------------
# 11. ANOMALY DETECTION
# ------------------------------------------------------------
Rule-based detection:

sli < 0.90 OR burn_rate > 1.0


Design intent:

- no ML dependency
- fully explainable
- deterministic SRE signals


# ------------------------------------------------------------
# 12. PROMETHEUS INTEGRATION LAYER
# ------------------------------------------------------------
Exposed metrics:

- slo_success_rate
- error_budget_burn_rate
- error_budget_remaining
- github_health_score
- github_anomaly_flag

Exported via:

start_http_server(8000)


# ------------------------------------------------------------
# 13. DESIGN TRADEOFFS (INTERVIEW CRITICAL)
# ------------------------------------------------------------


# 13.1 WHY SQLITE INSTEAD OF KAFKA?
# ------------------------------------------------------------
✔ simple replay model
✔ no external infra
✔ deterministic state

Tradeoff:

- not horizontally scalable


# 13.2 WHY WINDOWED COMPUTATION?
# ------------------------------------------------------------
✔ avoids noisy signals
✔ stabilizes SLO evaluation
✔ aligns with real SRE burn-rate windows


# 13.3 WHY RULE-BASED ANOMALY DETECTION?
# ------------------------------------------------------------
✔ explainable
✔ deterministic
✔ production-aligned
✔ easy debugging


# ------------------------------------------------------------
# 14. KEY INSIGHT — WHAT THIS SYSTEM REALLY IS
# ------------------------------------------------------------
The SRE engine is not just a metrics calculator.

It is:

A reliability control system that simulates production-grade SLO evaluation pipelines over an event-sourced system


It bridges:

- event systems (GitHub, CI/CD)
- infrastructure signals (GitOps)
- reliability math (SLO, burn rate)
- observability (Prometheus + Grafana)


# ------------------------------------------------------------
# 15. FINAL ARCHITECTURE IDENTITY
# ------------------------------------------------------------
If GitOps exporter answers:

“What is the current state of the cluster?”

And GitHub exporter answers:

“What is happening in the engineering workflow?”

Then SRE engine answers:

“Are we heading toward failure or stability?”
