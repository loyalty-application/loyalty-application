terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.8.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

# providers
provider "aws" {
  alias  = "primary"
  region = "ap-southeast-1"
}

# create a zone with your domain name
resource "aws_route53_zone" "this" {
  name = var.dns_domain_name
}

# setup the name servers
resource "aws_route53domains_registered_domain" "this" {
  domain_name = var.dns_domain_name
  dynamic "name_server" {
    for_each = range(length(aws_route53_zone.this.name_servers))
    content {
      name = aws_route53_zone.this.name_servers[name_server.key]
    }
  }
}

# setup global document db
resource "aws_docdb_global_cluster" "this" {
  global_cluster_identifier = "${var.project_name}-docdb-global"
  engine                    = "docdb"
  engine_version            = "4.0.0"
}



# iam roles required
resource "aws_iam_role" "instance_role" {
  name                  = "iam_role_ecs_instance"
  path                  = "/"
  assume_role_policy    = data.aws_iam_policy_document.ecs_instance_policy.json
  force_detach_policies = true
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "aws_iam_role" "service_role" {
  name                  = "iam_role_ecs_service"
  path                  = "/"
  assume_role_policy    = data.aws_iam_policy_document.ecs_service_policy.json
  force_detach_policies = true
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "aws_iam_instance_profile" "instance_profile" {
  name = "aws_iam_instance_profile"
  path = "/"
  role = aws_iam_role.instance_role.id
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "aws_iam_role_policy_attachment" "instance" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "service" {
  role       = aws_iam_role.service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
