# required fields
# aws
variable "aws_account_id" {
  type        = string
  description = "your aws account id"
}

variable "aws_regions" {
  type        = list(string)
  description = "aws regions you're deploying in"
}

# dns
variable "dns_domain_name" {
  type        = string
  description = "the domain you're deploying the app to"
}

# optional fields

variable "project_name" {
  type        = string
  description = "name for this project"
  default     = "loyalty-application"
}
