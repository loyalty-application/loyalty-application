variable "project_name" {
  type = string
}
variable "project_domain" {
  type = string
}

variable "network_subnet_availability_zones" {
  type        = list(string)
  description = "List of availability zones, with each element representing an aws availability zone"
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}
variable "network_subnet_private_cidrs" {
  type        = list(string)
  description = "List of cidr blocks, with each element repesenting a private subnet"
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

}
variable "network_subnet_public_cidrs" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
}
variable "network_vpc_cidr" {
  type        = string
  description = "network address of VPC"
  default     = "10.0.0.0/20"
}


variable "aws_lb_dns_name" {
  type = string
}

variable "network_nameservers" {
    type = list(string)
}
