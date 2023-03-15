variable "key_pair_name" {
  type = string
}
variable "key_pair_public_key" {
  type = string
}


variable "network_subnet_private_cidrs" {
  type = list(string)
}
variable "network_subnet_availability_zones" {
  type = list(string)
}
variable "network_vpc_cidr" {
  type = string
}


variable "ecr_name" {
  type = string
}


variable "ec2_ami" {
  type = string
}

variable "ec2_instance_type" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}
