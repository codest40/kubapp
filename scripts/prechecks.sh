#!/bin/bash
set -euo pipefail

echo "Running Prechecks..."

kubectl cluster-info >/dev/null || {
  echo "❌ Cluster unreachable"
  exit 1
}

kubectl get ns argocd >/dev/null || {
  echo "❌ ArgoCD not installed"
  exit 1
}

test -f gitops/infra/root-app.yml || {
  echo "❌ root-app.yml missing"
  exit 1
}

echo "✅ Prechecks passed"
