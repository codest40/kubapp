#!/usr/bin/env bash
set -euo pipefail

ENV=${ENV:-dev}
WORKDIR=${WORKDIR:-.}
LOG_GROUP=${LOG_GROUP:-"/kubapp/${ENV}/audit-logs"}

cd "$WORKDIR"

echo "Running Terraform Drift Check for env=$ENV"

terraform init -input=false

set +e
terraform plan -detailed-exitcode -no-color -out=tfplan
EXIT_CODE=$?
set -e

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

TRACE_ID=$(terraform output -json 2>/dev/null | jq -r '.trace_id.value // "unknown"' || echo "unknown")

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ No drift detected"

  aws logs put-log-events \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name "drift-check" \
    --log-events "timestamp=$(date +%s%3N),message={\"event\":\"no_drift\",\"env\":\"$ENV\",\"trace_id\":\"$TRACE_ID\",\"timestamp\":\"$TIMESTAMP\"}"

elif [ $EXIT_CODE -eq 2 ]; then
  echo "⚠️ Drift detected!"

  terraform show -json tfplan > plan.json

  aws logs put-log-events \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name "drift-check" \
    --log-events "timestamp=$(date +%s%3N),message={\"event\":\"drift_detected\",\"env\":\"$ENV\",\"trace_id\":\"$TRACE_ID\",\"timestamp\":\"$TIMESTAMP\"}"

  exit 2

else
  echo "❌ Terraform plan failed"
  exit $EXIT_CODE
fi

