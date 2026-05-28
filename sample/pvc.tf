resource "kubernetes_storage_class" "efs" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = local.efs_id  #gotten later
    directoryPerms   = "700"
  }

  reclaim_policy      = "Retain"
  volume_binding_mode = "Immediate"
}



resource "kubernetes_persistent_volume_claim" "prometheus" {
  metadata {
    name      = "prometheus-pvc"
    namespace = "monitoring"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "20Gi"
      }
    }

    storage_class_name = kubernetes_storage_class.efs.metadata[0].name
  }
}

resource "kubernetes_persistent_volume_claim" "grafana" {
  metadata {
    name      = "grafana-pvc"
    namespace = "monitoring"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    resources {
      requests = {
        storage = "10Gi"
      }
    }

    storage_class_name = kubernetes_storage_class.efs.metadata[0].name
  }
}


