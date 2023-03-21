variable "aws" {
  sensitive = true
  type = object({
    region     = string
    account_id = string
  })
}

variable "atlas" {
  sensitive = true
  type = object({
    project_name   = string
    project_region = string
    project_id     = string
    username       = string
    password       = string
  })
}

variable "vpc" {
  type = object({
    id      = string
    cidr    = string
    subnets = list(string)
  })
}
