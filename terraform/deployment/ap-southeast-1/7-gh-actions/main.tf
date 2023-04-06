#terraform {
#required_providers {
#github = {
#source  = "integrations/github"
#version = "5.18.3"
#}
#}
#}

#provider "github" {
#token = var.github.access_token
#}


#data "github_repository" "kafka_connector" {
#full_name = var.projects.kafka_connector.gh_repo_url
#}

#resource "github_actions_secret" "ecr_repo_url" {
#repository      = data.github_repository.kafka_connector.name
#secret_name     = "ECR_REPO"
#plaintext_value = module.ecr.repository_url
#}

