#!/bin/bash
set -euo pipefail

# ============================================================
# DEBUG MODE (toggle with DEBUG=1 ./bootstrap_gitops.sh)
# ============================================================
DEBUG="${DEBUG:-0}"

log() {
  echo "========================================"
  echo "$1"
  echo "========================================"
}

run() {
  echo ""
  echo "➜ RUNNING: $*"
  if [[ "$DEBUG" == "1" ]]; then
    "$@" 2>&1 | tee /tmp/kubectl-debug.log
  else
    "$@"
  fi
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log "GitOps Bootstrap Starting..."
echo "ROOT: $ROOT"

# ============================================================
# PREVIEW MODE (safe dry-run)
# ============================================================
FILE="$ROOT/gitops/argocd/appset.yaml"

echo ""
echo "========================================"
echo " DRY RUN PREVIEW: $FILE"
echo "========================================"
kubectl apply -f "$FILE" --dry-run=client -o yaml | sed 's/^/  /'

echo ""
log "APPLYING ARGOCD APPSET"

run kubectl apply -n argocd -f "$ROOT/gitops/argocd/appset.yaml" -v=8

echo ""
log "APPLYING ARGOCD INGRESS"

run kubectl apply -n argocd -f "$ROOT/gitops/argocd/ingress.yaml" -v=8

echo ""
log "POST APPLY STATE (ARGOCD PODS)"
run kubectl get pods -n argocd -o wide

echo ""
log "ARGOCD APPLICATIONS (CRITICAL DEBUG STEP)"
run kubectl get applications -n argocd || true
run kubectl get applicationsets -n argocd -o wide || true

echo ""
log "CLUSTER STATE CHECK (dev namespace)"
run kubectl get pods -n dev -o wide || true
run kubectl get deploy -n dev || true
run kubectl get svc -n dev || true

echo ""
log "GitOps Bootstrap Complete"
