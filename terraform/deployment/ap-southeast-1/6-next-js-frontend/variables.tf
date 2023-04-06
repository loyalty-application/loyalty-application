# required variables --
variable "github" {
  type = object({
    access_token = string
    branch_name  = string
    repository   = string
  })
}

# optional variables --
variable "project_name" {
  type    = string
  default = "next-js-frontend"
}
