resource "null_resource" "wait_for_active_eks" {
  triggers = {
    cluster = local.cluster_name
  }

  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${local.cluster_name}"
  }
}

resource "null_resource" "wait_for_nodes" {
  depends_on = [null_resource.wait_for_active_eks]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=Ready nodes --all --timeout=10m"
  }
}


resource "null_resource" "wait_for_efs_csi" {
  depends_on = [helm_release.efs_csi]

  provisioner "local-exec" {
    command = <<EOT
echo "Waiting for EFS CSI controller..."

kubectl rollout status deployment efs-csi-controller -n kube-system --timeout=5m

echo "Waiting for EFS CSI node daemonset..."

kubectl rollout status daemonset efs-csi-node -n kube-system --timeout=5m

echo "EFS CSI fully ready"
EOT
  }
}


resource "kubernetes_config_map_v1" "cluster_readiness" {
  metadata {
    name      = "cluster-readiness"
    namespace = "kube-system"
  }

  data = {
    status    = "initializing"
    cluster   = local.cluster_name
    timestamp = timestamp()
    version   = "1.31"
  }
}

resource "null_resource" "mark_cluster_ready" {
  depends_on = [
    helm_release.argocd
  ]

  provisioner "local-exec" {
    command = <<EOT
kubectl patch configmap cluster-readiness -n kube-system \
  --type merge \
  -p '{
    "data": {
      "status": "ready",
      "timestamp": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"
    }
  }'
EOT
  }
}


