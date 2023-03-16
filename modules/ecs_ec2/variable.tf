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
  default = 8
}


variable "ecs_cluster_name" {
  type = string
}
variable "ecs_asg_name" {
  type = string
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


