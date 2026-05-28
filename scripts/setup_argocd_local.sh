#!/bin/bash
set -euo pipefail

ARGO_NS="argocd"
APP="${1:-admin-dev}"

echo "===================================="
echo "ArgoCD Setup + Auto Connect"
echo "App: $APP"
echo "===================================="

# -------------------------------
# 1. Install ArgoCD CLI if missing
# -------------------------------
if ! command -v argocd >/dev/null 2>&1; then
  echo "ArgoCD CLI not found → installing..."

  curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  chmod +x argocd
  sudo mv argocd /usr/local/bin/

  echo "✅ ArgoCD CLI installed"
else
  echo "✅ ArgoCD CLI already installed"
fi

# -------------------------------
# 2. Check if ArgoCD is installed in cluster
# -------------------------------
echo "Checking ArgoCD in cluster..."

kubectl get ns "$ARGO_NS" >/dev/null 2>&1 || {
  echo "❌ ArgoCD namespace not found"
  exit 1
}

kubectl get svc -n "$ARGO_NS" >/dev/null

# -------------------------------
# 3. Detect ArgoCD server
# -------------------------------
echo "Detecting ArgoCD server..."

SERVER_TYPE=$(kubectl get svc argocd-server -n "$ARGO_NS" -o jsonpath='{.spec.type}')

if [[ "$SERVER_TYPE" == "LoadBalancer" ]]; then
  SERVER=$(kubectl get svc argocd-server -n "$ARGO_NS" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  echo "ArgoCD exposed via LoadBalancer:"
  echo "$SERVER"

elif [[ "$SERVER_TYPE" == "ClusterIP" ]]; then
  echo "ArgoCD is ClusterIP → using port-forward"

  kubectl port-forward svc/argocd-server -n "$ARGO_NS" 8080:443 >/dev/null 2>&1 &
  PF_PID=$!

  sleep 3
  SERVER="localhost:8080"
  echo "ArgoCD available at: $SERVER"
else
  echo "❌ Unknown service type: $SERVER_TYPE"
  exit 1
fi

# -------------------------------
# 4. Test connectivity
# -------------------------------
echo "Testing connection..."

argocd login "$SERVER" --username admin --password admin --insecure >/dev/null 2>&1 || {
  echo "⚠️ Login failed (check credentials)"
}

# -------------------------------
# 5. Sync app
# -------------------------------
echo "Syncing app: $APP"

argocd app sync "$APP" || {
  echo "❌ Sync failed"
  exit 1
}

argocd app refresh "$APP"

echo "===================================="
echo "DONE"
echo "===================================="

# -------------------------------
# Cleanup port-forward
# -------------------------------
if [[ -n "${PF_PID:-}" ]]; then
  kill "$PF_PID" || true
fi
