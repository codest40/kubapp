resource "kubernetes_service_account_v1" "lb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = local.lb_controller_role_arn
    }
  }
}

resource "kubernetes_service_account_v1" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = local.external_dns_role_arn
    }
  }
}

resource "kubernetes_service_account_v1" "fluentbit" {
  metadata {
    name      = "fluent-bit"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = local.fluentbit_role_arn
    }
  }
}

resource "kubernetes_service_account_v1" "efs_csi" {
  metadata {
    name      = "efs-csi-controller-sa"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = local.efs_role_arn
    }
  }
}
