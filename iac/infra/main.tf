############################################
# AUTH DATA
############################################

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "main" {
  name         = var.root_domain
  private_zone = false
}

############################################
# NETWORK
############################################

module "network" {
  source = "./modules/network"

  name     = local.name_prefix
  vpc_cidr = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  vpc_flow_log    = local.vpc_flow_log
  tags = merge(local.common_tags, {
    Name = local.name_prefix
  })
}

############################################
# SG PREP
############################################

module "sg_prep" {
  source = "./modules/sg-prep"

  from_port_ec2_app = 3000
  to_port_ec2_app   = 3000

  from_port_fargate_app = 4000
  to_port_fargate_app   = 4000

  from_port_cache_app = 6379
  to_port_cache_app   = 6379

  private_subnets_cidr = ["10.0.11.0/24", "10.0.12.0/24"]

  custom_sg_definitions = {}

  tags = local.common_tags
}

############################################
# SECURITY
############################################
module "security" {
  source = "./modules/security"

  vpc_id         = module.network.vpc_id
  sg_definitions = module.sg_prep.sg_definitions

  name_prefix = local.name_prefix

  tags = local.common_tags
}

############################################
# IAM 
############################################
module "iam_core" {
  source       = "./modules/iam-core"
  cluster_name = local.cluster_name
  tags         = local.common_tags
}

# Roles
module "iam_irsa" {
  source = "./modules/iam-irsa"

  cluster_name      = local.cluster_name
  region            = var.region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  hosted_zone_id    = data.aws_route53_zone.main.zone_id
  account_id        = data.aws_caller_identity.current.account_id

  tags = local.common_tags

  depends_on = [module.eks]
}

############################################
# EKS
############################################
module "eks" {
  source = "./modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_v

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  sg_ids = module.security.sg_ids

  cluster_role_arn = module.iam_core.eks_cluster_role_arn
  node_role_arn    = module.iam_core.node_group_role_arn
  fargate_role_arn = module.iam_core.fargate_role_arn
  access_iam_arn   = var.access_iam_arn

  node_instance_type    = "t3.medium"
  node_desired_capacity = 2
  node_min_capacity     = 1
  node_max_capacity     = 3

  tags = local.common_tags
  depends_on = [
    module.logging
  ]
}

############################################
# CLOUDWATCH
############################################

module "logging" {
  source      = "./modules/logging"
  log_groups  = local.app_log_groups
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

############################################
# EFS       
############################################
module "efs" {
  source = "./modules/efs"

  vpc_id      = module.network.vpc_id
  vpc_cidr    = "10.0.0.0/16"
  name_prefix = local.name_prefix
  subnet_ids  = module.network.private_subnet_ids
  tags        = local.common_tags
}

############################################
# ECR
############################################
#module "ecr" {
#  source = "./modules/ecr"
#  name_prefix = local.name_prefix
#  repositories = ["user", "admin", "monitoring"]
#  tags = local.common_tags
#}

