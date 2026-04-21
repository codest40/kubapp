variable "cluster_name" {
  description = "EKS cluster name (used for naming IAM roles)"
  type        = string
}

variable "tags" {
  description = "Tags applied to all IAM resources"
  type        = map(string)
  default     = {}
}
