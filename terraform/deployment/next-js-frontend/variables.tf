variable "aws" {
  type = object({
    region = string
  })
}

variable "github" {
  type = object({
    access_token = string
    branch_name  = string
    repository   = string
  })
}

variable "project" {
  type = object({
    name = string
  })
}

variable "dns" {
  type = object({
    domain_name = string
  })
}
