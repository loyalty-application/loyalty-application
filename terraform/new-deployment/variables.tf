variable "aws_config" {
  type = object({
    region     = string
    account_id = string
  })
}

variable "vpc" {
  type = object({
    cidr            = string
    azs             = list(string)
    private_subnets = list(string)
    public_subnets  = list(string)
  })
}

variable "dns" {
  type = object({
    domain_name = string
  })
}
