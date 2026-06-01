#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[CODEBASE RUNNER] $1"
}

log "Starting KubApp SysMonitor codebase pipeline"

# ============================================================
# STEP 1: Discovery
# ============================================================
log "Running discovery"
bash "$BASE_DIR/discovery.sh" || log "discovery failed (non-blocking)"

# ============================================================
# STEP 2: Drift
# ============================================================
log "Running drift analysis"
bash "$BASE_DIR/drift.sh" || log "drift failed (non-blocking)"

# ============================================================
# STEP 3: Architecture
# ============================================================
log "Running architecture checks"
bash "$BASE_DIR/architecture.sh" || log "architecture failed (non-blocking)"

# ============================================================
# STEP 4: Security
# ============================================================
log "Running security checks"
bash "$BASE_DIR/security.sh" || log "security failed (non-blocking)"

# ============================================================
# STEP 5: Validation
# ============================================================
log "Running validation checks"
bash "$BASE_DIR/validation.sh" || log "validation failed (non-blocking)"

# ============================================================
# STEP 6: METRICS (MUST BE LAST)
# ============================================================
log "Generating Prometheus metrics"
bash "$BASE_DIR/metrics.sh"

log "Pipeline completed"
