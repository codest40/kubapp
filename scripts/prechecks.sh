#!/bin/bash
set -euo pipefail


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Running Prechecks..."

kubectl cluster-info >/dev/null || {
  echo "❌ Cluster unreachable"
  exit 1
}

kubectl get ns argocd >/dev/null || {
  echo "❌ ArgoCD not installed"
  exit 1
}

test -f "$ROOT/gitops/argocd/appset.yaml" || {
  echo "❌ appset.yml missing"
  exit 1
}

test -f "$ROOT/gitops/argocd/ingress.yaml" || {
  echo "❌ ingress.yml missing"
  exit 1
}

echo "✅ Prechecks passed"
