variable "project_name" {
  type    = string
  default = "loyalty-app-demo"
}
variable "ec2_ami" {
  type    = string
  default = "ami-08935252a36e25f85"
}
variable "ec2_instance_type" {
  type    = string
  default = "t2.micro"
}
variable "ec2_volume_type" {
  type    = string
  default = "gp2"
}
variable "ec2_volume_size" {
  type    = number
  default = 30
}

variable "network_security_groups" {
  type = list(string)
}
variable "network_subnets" {
  type        = list(string)
  description = "subnets to deploy the resources over"
}
variable "network_vpc_id" {
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

variable "ssl_certificate_arn" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "health_check_path" {
  type = string
}

variable "key_pair_name" {
  type = string
}
variable "key_pair_public_key" {
  type      = string
  sensitive = true
}

variable "iam_ecs_service_role" {
  type = string
}
variable "iam_ecs_instance_role" {
  type = string
}
variable "iam_ecs_instance_profile" {
  type = string
}

