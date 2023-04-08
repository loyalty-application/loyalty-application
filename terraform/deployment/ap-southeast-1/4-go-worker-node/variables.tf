# required variables ---


# optional variables ---
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
    asg = {
      desired_capacity = 1
      max_size         = 2
      min_size         = 1
    }
    instance_type = "t3.medium"
  }
}

variable "SMTP_PORT" {
  type    = number
  default = 587
}
variable "SMTP_SERVER" {
  type    = string
  default = ""
}
variable "SMTP_USERNAME" {
  type    = string
  default = ""
}
variable "SMTP_PASSWORD" {
  type    = string
  default = ""
}
variable "SENDER_EMAIL" {
  type    = string
  default = ""
}

# environment variables for task definition
variable "ENV" {
  sensitive = true
  type      = map(string)
  default = {
    "SERVER_PORT" = 8080
  }
}

# optional variables --- 
variable "project_name" {
  type        = string
  description = "name for the project"
  default     = "go-worker-node"
}
