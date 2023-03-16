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
variable "ec2_iam_instance_profile" {
  type = string
}
variable "ec2_vpc_security_group_ids" {
  type = list(string)
}
variable "ec2_key_pair_name" {
  type = string
}
variable "ec2_volume_type" {
  type    = string
  default = "gp2"
}
variable "ec2_volume_size" {
  type    = number
  default = 30
}


variable "ecs_asg_subnets" {
  type = list(string)
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

