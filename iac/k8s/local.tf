
data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "kubapp-tf-state"
    key    = "${var.env}/infra/terraform.tfstate"
    region = var.region
  }
}

locals {
  env                      = try(data.terraform_remote_state.infra.outputs.env, "${var.env}")
  vpc_id                   = data.terraform_remote_state.infra.outputs.vpc_id
  cluster_name             = try(data.terraform_remote_state.infra.outputs.cluster_name, "${var.project}-${var.env}")
  cluster_endpoint         = data.terraform_remote_state.infra.outputs.cluster_endpoint
  cluster_ca_cert          = data.terraform_remote_state.infra.outputs.cluster_ca_certificate
  lb_controller_role_arn   = data.terraform_remote_state.infra.outputs.lb_controller_role_arn
  external_dns_role_arn    = data.terraform_remote_state.infra.outputs.external_dns_role_arn
  domain                   = data.terraform_remote_state.infra.outputs.domain
  cert_arn                 = data.terraform_remote_state.infra.outputs.cert_arn
  fluentbit_role_arn       = data.terraform_remote_state.infra.outputs.fluentbit_role_arn
  efs_role_arn             = data.terraform_remote_state.infra.outputs.efs_role_arn
  efs_id                   = data.terraform_remote_state.infra.outputs.efs_id
  efs_dns_name             = data.terraform_remote_state.infra.outputs.efs_dns_name
  efs_security_group_id    = data.terraform_remote_state.infra.outputs.efs_security_group_id
  efs_user_app_ap_id       = data.terraform_remote_state.infra.outputs.efs_user_app_ap_id
  efs_admin_app_ap_id      = data.terraform_remote_state.infra.outputs.efs_admin_app_ap_id
  efs_monitoring_app_ap_id = data.terraform_remote_state.infra.outputs.efs_monitoring_app_ap_id
  app_logs                 = data.terraform_remote_state.infra.outputs.log_group_names["app_logs"]
}

locals {
  name_prefix = "kubapp-${var.env}"

  common_tags = {
    Environment = var.env
    Project     = var.project
  }
}

#data "terraform_remote_state" "infra" {
#  backend = "local"

#  config = {
#    path = "../infra/terraform.tfstate"
#  }
#}

