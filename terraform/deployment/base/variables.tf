variable "project" {
  type = object({
    name = string
  })

}
variable "aws" {
  type = object({
    region = string
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

variable "key_pairs" {
  type = map(string)
}