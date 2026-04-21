variable "cluster_name" {
  type = string
}

variable "access_iam_arn" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "sg_ids" {
  type = map(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "node_instance_type" {
  type = string
}

variable "node_desired_capacity" {
  type = number
}

variable "node_min_capacity" {
  type = number
}

variable "node_max_capacity" {
  type = number
}

# IAM MODULE INPUTS
variable "cluster_role_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}

variable "fargate_role_arn" {
  type = string
}

variable "fargate_workloads" {
  type = set(string)
  default = [
    "users",
    "monitoring",
    "landing"
  ]
}
