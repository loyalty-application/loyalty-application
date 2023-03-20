# project configs
variable "project" {
  type = object({
    name = string
  })
}

# environment variables to pass to task definition
variable "ENV" {
  sensitive = true
  type      = map(string)
}

# iam roles required by service
variable "iam" {
  type = object({
    service_role_arn = string
  })
}

# ecs related configs
variable "ecs" {
  type = object({
    cluster = object({
      id = string
    })
  })
}

# target group references
variable "tg" {
  type = object({
    arn = string
  })
}

# capacity provider references
variable "cp" {
  type = object({
    name = string
  })
}
