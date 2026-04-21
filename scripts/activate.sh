#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"

echo "=============================="
echo "ACTIVATION PIPELINE"
echo "ENV: $ENV"
echo "=============================="

############################################
# 1. VALIDATION (STRICT)
############################################
./scripts/validate.sh "$ENV"

############################################
# 2. PRE-FLIGHT EXECUTION SCRIPTS
############################################
echo "Running preflight scripts..."

./scripts/encrypt_secrets.sh "$ENV"
./scripts/validate_gitops.sh

############################################
# 3. GIT PUSH (ONLY IF USER CONFIRMS)
############################################
read -rp "Push to GitHub? (yes/no): " CONFIRM

if [[ "$CONFIRM" == "yes" ]]; then
  git add .
  git commit -m "chore: activate pipeline for $ENV" || echo "No changes"
  git push
  echo "✅ Pushed to GitHub"
else
  echo "Skipped push"
fi

echo "=============================="
echo "✅ ACTIVATION COMPLETE"
echo "=============================="
