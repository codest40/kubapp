locals {
  # Base naming
  name_prefix = "${var.project}-${var.env}"

  # Cluster name (env-isolated)
  cluster_name = "${var.cluster_name}-${var.env}"

  # Domain strategy
  full_domain = (var.env == "prod"
    ? "${var.subdomain}.${var.root_domain}"
    : "${var.env}.${var.subdomain}.${var.root_domain}"
  )

  # Common tags
  common_tags = {
    Project     = var.project
    Environment = var.env
  }

  # ----------------------------
  # App log groups (custom)
  # ----------------------------
  app_log_groups = {
    app_logs = {
      name      = "/${var.project}/${var.env}/app-logs"
      retention = var.log_groups.app_logs.retention
    }

    audit_logs = {
      name      = "/${var.project}/${var.env}/audit-logs"
      retention = var.log_groups.audit_logs.retention
    }
  }

  # ----------------------------
  # EKS system log group
  # ----------------------------
  eks_cluster_log_group = {
    name      = "/aws/eks/${local.cluster_name}/cluster"
    retention = var.log_groups.cluster_logs.retention
  }

  vpc_flow_log = {
    name      = "/aws/vpc/${local.cluster_name}-flowlogs"
    retention = var.log_groups.vpc_logs.retention
  }
}
