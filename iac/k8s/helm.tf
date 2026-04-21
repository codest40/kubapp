resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  values = [
    yamlencode({
      clusterName = local.cluster_name

      serviceAccount = {
        create = false
        name   = kubernetes_service_account_v1.lb_controller.metadata[0].name
      }

      region      = var.region
      vpcId       = local.vpc_id
      installCRDs = true
    })
  ]

  timeout         = 600
  wait            = true
  cleanup_on_fail = true

  depends_on = [
    null_resource.wait_for_nodes,
    kubernetes_service_account_v1.lb_controller
  ]
}

resource "helm_release" "external_dns" {
  name      = "external-dns"
  namespace = "kube-system"

  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "policy"
    value = "upsert-only"
  }

  set {
    name  = "sources[0]"
    value = "ingress"
  }

  set {
    name  = "txtOwnerId"
    value = local.name_prefix
  }

  set {
    name  = "txtPrefix"
    value = "extdns-"
  }

  set {
    name  = "domainFilters[0]"
    value = var.domain
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account_v1.external_dns.metadata[0].name
  }

  depends_on = [
    kubernetes_service_account_v1.external_dns,
    helm_release.lb_controller
  ]
}

resource "helm_release" "argocd" {
  name      = "argocd"
  namespace = kubernetes_namespace_v1.argocd.metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.7.0"

  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
      }
    })
  ]

  timeout         = 2000
  wait            = true
  cleanup_on_fail = true

  depends_on = [
    kubernetes_namespace_v1.argocd,
    helm_release.lb_controller,
    helm_release.fluentbit
  ]
}


resource "helm_release" "efs_csi" {
  name      = "aws-efs-csi-driver"
  namespace = "kube-system"

  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart      = "aws-efs-csi-driver"

  version = "2.5.0"

  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "controller.serviceAccount.name"
    value = kubernetes_service_account_v1.efs_csi.metadata[0].name
  }

  timeout         = 900
  wait            = true
  cleanup_on_fail = true

  values = [
    yamlencode({
      node = {
        nodeSelector = {
          "eks.amazonaws.com/compute-type" = "ec2"
        }
      }
    })
  ]

  depends_on = [
    helm_release.lb_controller,
    helm_release.external_dns,
    kubernetes_service_account_v1.efs_csi
  ]
}

resource "helm_release" "fluentbit" {
  name      = "fluent-bit"
  namespace = "kube-system"

  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"

  version         = "0.47.0"
  timeout         = 1200
  wait            = true
  cleanup_on_fail = true

  values = [
    yamlencode({
      cloudWatch = {
        enabled         = true
        region          = var.region
        logGroupName    = local.app_logs
        logStreamPrefix = "fluentbit"
      },
      serviceAccount = {
        create = false
        name   = "fluent-bit"
      },
      nodeSelector = {
        "eks.amazonaws.com/compute-type" = "ec2"
      }
    })
  ]

  depends_on = [
    helm_release.efs_csi,
    kubernetes_service_account_v1.fluentbit
  ]
}

#resource "helm_release" "kube_prometheus_stack" {
#  name      = "kube-prometheus-stack"
#  namespace = kubernetes_namespace_v1.monitoring.metadata[0].name

#  repository = "https://prometheus-community.github.io/helm-charts"
#  chart      = "kube-prometheus-stack"

#  version = "58.0.0"
#  timeout = 2000
#  wait    = true
#  cleanup_on_fail = true

#  values = [
#    yamlencode({
#      grafana = {
#        service = {
#          type = "LoadBalancer"
#        }
#      },
#      nodeSelector = {
#        "eks.amazonaws.com/compute-type" = "ec2"
#      }
#    })
#  ]

#  depends_on = [
#    helm_release.efs_csi,
#    helm_release.fluentbit,
#    helm_release.argocd,
#    kubernetes_namespace_v1.monitoring
#  ]
#}
