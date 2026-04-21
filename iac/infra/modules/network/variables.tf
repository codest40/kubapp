variable "name" {
  description = "Base name for the network resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_flow_log" {
  description = "CloudWatch log group configuration for VPC flow logs"
  type = object({
    name      = string
    retention = number
  })
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "tags" {
  description = "Base ags for the network resources"
  type        = map(string)
  default     = {}
}
