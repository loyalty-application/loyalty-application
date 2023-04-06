terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

# use state from global
data "terraform_remote_state" "global" {
  backend = "local"
  config = {
    path = "../../global/terraform.tfstate"
  }
}

# use state from region
data "terraform_remote_state" "region" {
  backend = "local"
  config = {
    path = "../1-region/terraform.tfstate"
  }
}

provider "aws" {
  region = local.aws_region
}

# local variables that declare what we need
locals {
  # reference the state as global
  global = data.terraform_remote_state.global.outputs
  region = data.terraform_remote_state.region.outputs

  # variables that we need from the remote state
  domain_name = local.global.dns.route53_domains.domain_name
  aws_region  = local.region.aws.aws_region
}
resource "aws_amplify_app" "this" {
  name       = var.project_name
  repository = var.github.repository

  # GitHub personal access token
  access_token = var.github.access_token

  # The default build_spec added by the Amplify Console for React.
  build_spec = <<-EOT
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
EOT

  auto_branch_creation_config {
    enable_auto_build = true
  }
}

# associate branch with amplify
resource "aws_amplify_branch" "this" {
  app_id      = aws_amplify_app.this.id
  branch_name = var.github.branch_name
}

# associate domain with project
resource "aws_amplify_domain_association" "this" {
  app_id      = aws_amplify_app.this.id
  domain_name = local.domain_name
  sub_domain {
    branch_name = aws_amplify_branch.this.branch_name
    prefix      = ""
  }
}
