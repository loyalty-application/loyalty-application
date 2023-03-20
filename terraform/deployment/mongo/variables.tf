variable "aws" {
  type = object({
    region     = string
    account_id = string
  })
}

variable "atlas" {
  type = object({
    project_region = string
    project_id     = string
  })
}

variable "vpc" {
  type = object({
    id             = string
    cidr           = string
    public_subnets = list(string)
  })
}
