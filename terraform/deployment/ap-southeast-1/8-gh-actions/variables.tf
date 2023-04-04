variable "repository_urls" {
  type    = list(string)
  default = []
}

variable "github" {
  type = object({
    access_token = string
  })
}
