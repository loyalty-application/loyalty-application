variable "ec2_ami" {
  type    = string
  default = "ami-08935252a36e25f85"
}

variable "ec2_subnet_id" {
  type = string
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

variable "ecs_cluster_name" {
  type = string
}
