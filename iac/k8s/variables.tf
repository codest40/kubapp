variable "env" {
  description = "Environment name (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be either 'dev', 'staging' or 'prod'."
  }
}

variable "project" {
  type    = string
  default = "kubapp-project"
}

variable "region" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "alert_email_password" {
  type      = string
  sensitive = true
}

variable "main_domain" {
  type = string
}

