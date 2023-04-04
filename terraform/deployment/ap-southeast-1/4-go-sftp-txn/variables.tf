# required variables ---
variable "SFTP_USERNAME" {
  sensitive = true
  type      = string
}
variable "SFTP_PASSWORD" {
  sensitive = true
  type      = string
}
variable "SFTP_HOST" {
  sensitive = true
  type      = string
}


# optional variables
# connector host for the init script
variable "CONNECTOR_HOST" {
  type    = string
  default = "https://kafka-connect.itsag1t6.com"
}

#project
variable "project_name" {
  type        = string
  description = "name for the project"
  default     = "go-sftp-txn"
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
    asg = {
      desired_capacity = 1
      max_size         = 2
      min_size         = 1
    }
    instance_type = "t3.small"
  }
}

