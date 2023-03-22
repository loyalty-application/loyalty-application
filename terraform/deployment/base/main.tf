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
  region = var.aws.region
}

locals {
  project_name = var.project.name
}

# create security groups
resource "aws_security_group" "this" {
  name   = "${var.project.name}-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "allow all"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# create vpc
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.19.0"
  name                 = local.project_name
  cidr                 = var.vpc.cidr
  azs                  = var.vpc.azs
  private_subnets      = var.vpc.private_subnets
  public_subnets       = var.vpc.public_subnets
  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dhcp_options  = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# create zones
resource "aws_route53_zone" "this" {
  name = var.dns.domain_name
}
# use new zone's dns
resource "aws_route53domains_registered_domain" "this" {
  domain_name = var.dns.domain_name
  dynamic "name_server" {
    for_each = range(length(aws_route53_zone.this.name_servers))
    content {
      name = aws_route53_zone.this.name_servers[name_server.key]
    }
  }
}
# provision wildcard certificate
resource "aws_acm_certificate" "this" {
  domain_name       = "*.${var.dns.domain_name}"
  validation_method = "DNS"
}

# create records for dns validation of certificate
resource "aws_route53_record" "this" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.this.zone_id

}
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.this : record.fqdn]
  depends_on = [
    aws_route53_record.this
  ]
}

# create key pairs
resource "aws_key_pair" "this" {
  for_each   = var.key_pairs
  key_name   = each.key
  public_key = each.value
}

# iam roles and policies
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

locals {
  project_names = ["nextjs-frontend", "go-gin-backend", "go-worker-node", "go-sftp-txn"]
}

module "ecr" {
  source          = "terraform-aws-modules/ecr/aws"
  version         = "1.6.0"
  for_each        = toset(local.project_names)
  repository_name = each.key
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
  # set to false if true when destroying
  repository_force_delete = false
}

# create efs 
resource "aws_efs_file_system" "this" {
  creation_token = "${local.project_names[0]}-fs"
}

# create mount target 
resource "aws_efs_mount_target" "this" {
  count           = length(module.vpc.public_subnets)
  subnet_id       = module.vpc.public_subnets[count.index]
  file_system_id  = aws_efs_file_system.this.id
  security_groups = [aws_security_group.this.id]
}

