variable "project_name" {
  type = string
}
variable "key_pair_name" {
  type = string
}
variable "key_pair_public_key" {
  type = string
}


variable "network_vpc_cidr" {
  type = string
}
variable "network_subnet_availability_zones" {
  type = list(string)
}
variable "network_subnet_private_cidrs" {
  type = list(string)
}
variable "network_subnet_public_cidrs" {
  type = list(string)
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

variable "ecs_asg_name" {
  type = string
}
variable "ecs_asg_desired_capacity" {
  type = number
}
variable "ecs_asg_min_size" {
  type = number
}
variable "ecs_asg_max_size" {
  type = number
}
variable "ecs_asg_hc_grace_period" {
  type = number
}
variable "ecs_asg_hc_type" {
  type = string
}

variable "MONGO_HOST" {
  type      = string
  sensitive = true
}
variable "MONGO_PASSWORD" {
  type      = string
  sensitive = true
}
variable "MONGO_USERNAME" {
  type      = string
  sensitive = true
}
