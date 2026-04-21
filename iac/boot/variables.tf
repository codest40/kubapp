
variable "profile" {
  description = "AWS CLI profile used to create backend resources"
  type        = string
}

variable "region" {
  description = "AWS region for backend resources"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
}

variable "force_destroy_bucket" {
  type    = bool
  default = true
}

variable "lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
}
