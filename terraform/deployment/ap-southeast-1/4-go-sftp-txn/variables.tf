# required variables ---
variable "SFTP_URL" {
  sensitive   = true
  type        = string
  description = "SFTP URL to pull files from"
}

# optional variables
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

# connector host for the init script
variable "CONNECTOR_HOST" {
  type    = string
  default = "https://kafka-connect.itsag1t6.com"
}
