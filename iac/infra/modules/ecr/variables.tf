variable "name_prefix" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "repositories" {
  type    = set(string)
  default = ["user", "admin", "monitoring"]
}
