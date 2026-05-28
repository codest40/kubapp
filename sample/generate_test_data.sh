#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Remote Synthetic GitHub Webhook Generator
# ============================================================
# Sends synthetic GitHub webhook traffic to a deployed
# sys_monitor instance.
#
# Usage:
#   ./generate_test_data_remote.sh
#
# Optional:
#   WEBHOOK_URL=http://18.232.146.39:3000/webhook/github \
#   ./generate_test_data_remote.sh
#
# Expected SRE metrics:
#   - slo_success_rate       = 0.80
#   - error_budget_burn_rate = 4.0
#   - github_health_score    = reduced
#   - github_anomaly_flag    = 1
# ============================================================

WEBHOOK_URL="${WEBHOOK_URL:-http://3.216.132.162:3000/webhook/github}"
REPO="${REPO:-paragon40/kubapp}"
WORKFLOW="${WORKFLOW:-CI Pipeline}"

LINE="============================================================"

echo "$LINE"
echo "Generating synthetic GitHub webhook traffic"
echo "Target: $WEBHOOK_URL"
echo "Repository: $REPO"
echo "$LINE"

# ------------------------------------------------------------
# Helper function
# ------------------------------------------------------------
send() {
  local event_type="$1"
  local payload="$2"

  response=$(curl -sS -o /dev/null -w "%{http_code}" \
    -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -H "X-GitHub-Event: $event_type" \
    -d "$payload")

  if [[ "$response" != "200" ]]; then
    echo "ERROR: Failed to send $event_type event (HTTP $response)"
    exit 1
  fi
}

# ------------------------------------------------------------
# Connectivity check
# ------------------------------------------------------------
echo "Checking webhook availability..."

code=$(curl -sS -o /dev/null -w "%{http_code}" "$WEBHOOK_URL" || true)

# GET may return 405 Method Not Allowed, which is fine.
if [[ "$code" != "200" && "$code" != "405" ]]; then
  echo "ERROR: Webhook endpoint is not reachable (HTTP $code)"
  exit 1
fi

echo "Webhook endpoint is reachable."
echo

# ------------------------------------------------------------
# PUSH EVENTS
# ------------------------------------------------------------
echo "Generating push events..."
for i in {1..10}; do
  send "push" "{
    \"repository\": {\"full_name\": \"$REPO\"},
    \"after\": \"commit-$i\"
  }"
done

# ------------------------------------------------------------
# PULL REQUEST EVENTS
# ------------------------------------------------------------
echo "Generating pull request events..."
for action in opened synchronize reopened closed; do
  send "pull_request" "{
    \"action\": \"$action\",
    \"repository\": {\"full_name\": \"$REPO\"}
  }"
done

# ------------------------------------------------------------
# ISSUE EVENTS
# ------------------------------------------------------------
echo "Generating issue events..."
for state in open closed; do
  send "issues" "{
    \"action\": \"updated\",
    \"issue\": {\"state\": \"$state\"},
    \"repository\": {\"full_name\": \"$REPO\"}
  }"
done

# ------------------------------------------------------------
# WORKFLOW SUCCESSES
# ------------------------------------------------------------
echo "Generating successful workflow runs..."
for i in {1..8}; do
  send "workflow_run" "{
    \"repository\": {\"full_name\": \"$REPO\"},
    \"workflow_run\": {
      \"name\": \"$WORKFLOW\",
      \"status\": \"completed\",
      \"conclusion\": \"success\"
    }
  }"
done

# ------------------------------------------------------------
# WORKFLOW FAILURES
# ------------------------------------------------------------
echo "Generating failed workflow runs..."
for i in {1..2}; do
  send "workflow_run" "{
    \"repository\": {\"full_name\": \"$REPO\"},
    \"workflow_run\": {
      \"name\": \"$WORKFLOW\",
      \"status\": \"completed\",
      \"conclusion\": \"failure\"
    }
  }"
done

echo
echo "$LINE"
echo "Synthetic traffic generation complete"
echo "$LINE"
echo "Expected results:"
echo "  Workflow success rate: 80%"
echo "  SLO target:            95%"
echo "  Burn rate:             4.0"
echo "  Health score:          reduced"
echo "  Anomaly flag:          1"
echo "$LINE"

# Extract host from webhook URL
HOST=$(echo "$WEBHOOK_URL" | sed -E 's#http://([^/:]+).*#\1#')

echo "Grafana:    http://$HOST:3001"
echo "Prometheus: http://$HOST:9090"
echo "$LINE"
