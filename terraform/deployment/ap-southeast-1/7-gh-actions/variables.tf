#variable "github" {
#type = object({
#access_token = string
#})
#}

#variable "projects" {
#description = "names of ecr repositories to create for the project - note that this may not be required for you as this is for development"
#type = object({
#kafka_connector = object({
#gh_repo_url = string

#})
#go_worker_node = object({
#gh_repo_url = string

#})
#go_gin_backend = object({
#gh_repo_url = string

#})
#}
#)
#}
