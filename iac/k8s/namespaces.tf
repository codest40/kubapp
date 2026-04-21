resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"

    labels = {
      environment = var.env
      project     = var.project
      app         = "${local.name_prefix}-argocd"
    }
  }
}

resource "kubernetes_namespace_v1" "ingress" {
  metadata {
    name = "ingress"

    labels = {
      environment = var.env
      project     = var.project
      app         = "${local.name_prefix}-ingress"
    }
  }
}

resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      environment = var.env
      project     = var.project
      app         = "${local.name_prefix}-monitoring"
    }
  }
}

resource "kubernetes_namespace_v1" "users" {
  metadata {
    name = "users"

    labels = {
      environment = var.env
      project     = var.project
      app         = "${local.name_prefix}-users"
    }
  }
}

resource "kubernetes_namespace_v1" "admin" {
  metadata {
    name = "admin"

    labels = {
      environment = var.env
      project     = var.project
      app         = "${local.name_prefix}-admin"
    }
  }
}

#locals {
#  namespaces = ["argocd", "ingress", "monitoring", "users", "admin"]
#}

#resource "kubernetes_namespace_v1" "this" {
#  for_each = toset(local.namespaces)

#  metadata {
#    name = each.value

#    labels = {
#      environment = var.env
#      project     = var.project
#      app         = "${local.name_prefix}-${each.value}"
#    }
#  }
#}
