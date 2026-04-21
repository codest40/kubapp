variable "env" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging, or prod."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "kubapp"
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "access_iam_arn" {
  type = string
}

variable "kubernetes_v" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "CERT_ARN" {
  description = "ACM certificate ARN"
  type        = string
}

variable "root_domain" {
  description = "Base domain"
  type        = string
}

variable "subdomain" {
  description = "Service subdomain"
  type        = string
}

variable "cluster_name" {
  description = "Base cluster name (no env suffix here)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone"
  type        = string
}

variable "log_groups" {
  description = "CloudWatch log group definitions"
  type = map(object({
    retention = number
  }))
}
