# generic project specific names
variable "project" {
  type = object({
    name = string
  })
}

# key pair name - for ec2
variable "key_pair" {
  type = object({
    name = string
  })
}

# vpc configs
variable "vpc" {
  type = object({
    id      = string
    subnets = list(string)
  })
}

# ecs configs
variable "ecs" {
  type = object({
    instance_type      = string
    tg_arn             = string
    security_group_ids = list(string)
    asg = object({
      desired_capacity = number
      max_size         = number
      min_size         = number
    })
  })
}

# iam roles
variable "iam" {
  type = object({
    instance_profile_arn = string
    service_role_arn     = string
    instance_role_arn    = string
  })

}
