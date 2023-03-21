variable "aws" {
  type = object({
    region = string
  })
}

variable "vpc" {
  type = object({
    id      = string
    subnets = list(string)
  })
}
