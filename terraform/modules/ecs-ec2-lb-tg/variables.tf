variable "project" {
  type = object({
    name = string
  })
}

variable "vpc" {
  type = object({
    id      = string
    subnets = list(string)
  })

}

variable "tg" {
  type = object({
    hc = object({
      path                = string
      protocol            = string
      interval            = number
      matcher             = number
      healthy_threshold   = number
      unhealthy_threshold = number
    })
  })
}

variable "ecs" {
  type = object({
    asg = object({
      id = string
    })
  })
}

variable "lb" {
  type = object({
    security_group_ids = list(string)
  })
}

variable "certificate" {
  type = object({
    arn = string
  })
}
