terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_amplify_app" "this" {
  name       = var.project_name
  repository = var.github.repository

  # GitHub personal access token
  access_token = var.github.access_token
}

# associate branch with amplify
resource "aws_amplify_branch" "this" {
  app_id      = aws_amplify_app.this.id
  branch_name = var.github.branch_name
}

# associate domain with project
resource "aws_amplify_domain_association" "this" {
  app_id      = aws_amplify_app.this.id
  domain_name = var.dns.domain_name
  sub_domain {
    branch_name = aws_amplify_branch.this.branch_name
    prefix      = ""
  }
}
