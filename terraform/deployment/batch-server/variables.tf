# generic project specific names
variable "project" {
  type = object({
    name = string
  })
}

# aws configs
variable "aws" {
  type = object({
    region     = string
    account_id = string
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
    id                   = string
    cidr                 = string
    public_subnet_ids    = list(string)
    public_subnet_cidrs  = list(string)
    private_subnet_ids   = list(string)
    private_subnet_cidrs = list(string)
  })
}


# ecs configs
variable "ecs" {
  type = object({
    instance_type = string
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

# environment variables for task definition
variable "ENV" {
  sensitive = true
  type      = map(string)
}


variable "efs" {
  type = object({
    file_system_id = string
  })
}
