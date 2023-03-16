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

