variable "project_name" {
  type        = string
  description = "name for the project"
  default     = "go-gin-backend"
}

variable "project_name_prefix" {
  type        = string
  description = "short form name for the project"
  default     = "ggb"
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
  default = {
    instance_type = "t3.small"
    asg = {
      desired_capacity = 1
      max_size         = 2
      min_size         = 1
    }
  }
}

# target group
variable "tg" {
  type = object({
    port = number
    hc = object({
      path                = string
      protocol            = string
      interval            = number
      matcher             = number
      healthy_threshold   = number
      unhealthy_threshold = number
    })
  })
  default = {
    port = 8080
    hc = {
      path                = "/api/v1/health"
      protocol            = "HTTP"
      interval            = 30
      matcher             = "200"
      healthy_threshold   = 2
      unhealthy_threshold = 2
    }
  }
}


# jwt secret
variable "JWT_SECRET" {
  sensitive = true
  type      = string
  default   = "SOMESUPERSECRETOKEN"
}
