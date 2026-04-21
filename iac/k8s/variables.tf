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

variable "cert_arn" {
  type = string
}

variable "domain" {
  type = string
}

variable "DOCKER_PASSWORD" {
  type      = string
  sensitive = true
}

variable "DOCKER_USERNAME" {
  type      = string
  sensitive = true
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
