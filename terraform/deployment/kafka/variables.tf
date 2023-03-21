variable "aws" {
  type = object({
    region = string
  })
}

variable "vpc" {
  type = object({
    id                 = string
    cidr               = string
    private_subnet_ids = list(string)
    public_subnet_ids  = list(string)
  })
}
