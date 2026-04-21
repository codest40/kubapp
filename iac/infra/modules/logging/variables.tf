variable "name_prefix" {
  type = string
}

variable "log_groups" {
  description = "Map of log groups to create"
  type = map(object({
    name      = string
    retention = number
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}

