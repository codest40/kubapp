#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
LOG_DIR="logs"

mkdir -p "$LOG_DIR"

log_event() {
  local LEVEL="${1:-INFO}"
  local ACTION="${2:-unknown}"
  local SERVICE="${3:-unknown}"
  local ENVIRONMENT="${4:-unknown}"
  local MESSAGE="${5:-no-message}"

  local TIMESTAMP
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local LOG_FILE="$LOG_DIR/${ACTION}.log"

  local ENTRY
  ENTRY=$(printf \
    '[%s] level=%s action=%s service=%s env=%s message="%s"' \
    "$TIMESTAMP" \
    "$LEVEL" \
    "$ACTION" \
    "$SERVICE" \
    "$ENVIRONMENT" \
    "$MESSAGE"
  )

  echo "$ENTRY" | tee -a "$LOG_FILE"
}
