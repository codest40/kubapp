#!/bin/bash
set -euo pipefail

# Custom Kubernetes-style application manifests validator

source functions/check_data.sh

FILES=(
  "gitops/state/container/apps/weather.json"
  "gitops/state/container/apps/admin.json"
  "gitops/state/container/apps/auth.json"
)

echo "Starting manifest validation..."

for file in "${FILES[@]}"; do
  echo "Validating: $file"

  if [[ ! -f "$file" ]]; then
    echo "❌ File not found: $file"
    exit 1
  fi

  if ! check_non_empty_values "$file"; then
    echo "❌ Validation failed: $file"
    exit 1
  fi

done

echo "✅ All application manifests passed validation"
exit 0
