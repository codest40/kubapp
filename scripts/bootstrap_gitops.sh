#!/bin/bash
set -euo pipefail

echo "GitOps Bootstrap Starting..."

# Apply root application
kubectl apply -n argocd -f gitops/infra/root-app.yml

echo "✅ Root app applied"
echo "GitOps Bootstrap Complete"
