#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
TF_CREATED_NS=${TF_CREATED_NS:-()}
eval "TF_CREATED_NS=$TF_CREATED_NS"
#IFS=' ' read -r -a TF_CREATED_NS <<< "$TF_CREATED_NS"

echo "======================================"
echo " Kubernetes SAFE CLEANUP START"
echo "======================================"

########################################
# 0. SAFETY GUARD
########################################
if kubectl config current-context | grep -qi "prod"; then
  echo "❌ Refusing to run in prod context"
  exit 1
fi

########################################
# 1. DELETE APPLICATIONSETS (ROOT CONTROLLER)
########################################
echo ">> Deleting ApplicationSets..."
kubectl delete applicationsets.argoproj.io --all -n argocd --ignore-not-found || true

########################################
# 2. DELETE ARGOCD APPLICATIONS
########################################
echo ">> Deleting Argo Applications..."
kubectl delete applications.argoproj.io --all -n argocd --ignore-not-found || true

########################################
# 3. NAMESPACE CLEANUP
########################################

ALL_NS=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')

for ns in $ALL_NS; do

  # skip system namespaces
  case "$ns" in
    kube-system|default|kube-public|kube-node-lease|argocd)
      continue
      ;;
  esac

  echo ">> Cleaning namespace: $ns"

  if [[ "$ns" == "ingress" ]]; then
    echo "Ensuring ingress particularly is deleted to avoid lb madness..."
    kubectl delete ns "$ns"
    kubectl get ingress -A > ingress.txt
    echo "Show Result"
    cat ingress.txt
  fi

  kubectl delete all --all -n "$ns" --ignore-not-found || true
  kubectl delete ingress --all -n "$ns" --ignore-not-found || true
  kubectl delete pvc --all -n "$ns" --ignore-not-found || true
  kubectl delete svc --all -n  "$ns" --ignore-not-found || true
  kubectl delete secret --all -n  "$ns" --ignore-not-found || true
  kubectl delete configmap --all -n  "$ns" --ignore-not-found || true

  # skip terraform-managed namespaces
  for tf_ns in "${TF_CREATED_NS[@]}"; do
    if [[ "$ns" == "$tf_ns" ]]; then
      echo "Skipping Terraform-managed Namespace: $tf_ns"
      continue 2
    fi
  done

  echo "Deleting Namespace: $ns"
  kubectl delete ns "$ns" || true
done

########################################
# 4. INGRESS CHECK (LB SAFETY)
########################################
echo ">> Checking Ingress resources..."
kubectl get ingress -A || true

########################################
# 5. FINALIZER FIX (ONLY IF STUCK)
########################################
for ns in $ALL_NS; do
  STATUS=$(kubectl get ns "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || true)

  if [[ "$STATUS" == "Terminating" ]]; then
    echo "Force finalizer cleanup: $ns"

    kubectl patch ns "$ns" \
      -p '{"spec":{"finalizers":[]}}' --type=merge || true
  fi
done

########################################
# 6. FINAL STATE
########################################
echo ">> Final cluster state:"
kubectl get ns
kubectl get ingress -A || true
kubectl get applicationsets -n argocd || true

echo "======================================"
echo " CLEANUP COMPLETE"
echo "======================================"
