variable "cluster_id" {
  type = string
}

variable "cluster_capacity_provider_name" {
  type = string
}

variable "MONGO_HOST" {
  type      = string
  sensitive = true
}
variable "MONGO_PASSWORD" {
  type      = string
  sensitive = true
}
variable "MONGO_USERNAME" {
  type      = string
  sensitive = true
}
