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

# local variables that declare what we need
locals {
  # reference the state as global
  global = data.terraform_remote_state.global.outputs

  # variables that we need from the remote state
  aws_region           = local.global.aws.aws_regions[var.aws_region_index]
  dns_domain_name      = local.global.dns.route53_domains.id
  route53_zone_id      = local.global.dns.route53_zone.zone_id
  docdb_global_cluster = local.global.docdb.global_cluster
}

# aws provider configuration
provider "aws" {
  alias  = "primary"
  region = local.aws_region
}

# create public security group
resource "aws_security_group" "this" {
  name   = "${var.project_name}-public-sg"
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
  name                 = var.project_name
  cidr                 = var.vpc.cidr
  azs                  = var.vpc.azs
  private_subnets      = var.vpc.private_subnets
  public_subnets       = var.vpc.public_subnets
  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dhcp_options  = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}

# provision wildcard certificate for this region
resource "aws_acm_certificate" "this" {
  domain_name       = "*.${local.dns_domain_name}"
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
  zone_id         = local.route53_zone_id

}

# validate the wildcard certificate through dns
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


# create ecr repository for all projects 
module "ecr" {
  source          = "terraform-aws-modules/ecr/aws"
  version         = "1.6.0"
  for_each        = toset(var.ecr_project_names)
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
  creation_token = "${var.project_name}-efs"
}

# create mount target 
resource "aws_efs_mount_target" "this" {
  count           = length(module.vpc.private_subnets)
  subnet_id       = module.vpc.public_subnets[count.index]
  file_system_id  = aws_efs_file_system.this.id
  security_groups = [aws_security_group.this.id]
}

# subnet group for document db
resource "aws_docdb_subnet_group" "this" {
  name       = "${var.project_name}-${local.aws_region}-"
  subnet_ids = module.vpc.private_subnets
}

# create document db
resource "aws_docdb_cluster" "this" {
  engine                 = local.docdb_global_cluster.engine
  engine_version         = local.docdb_global_cluster.engine_version
  cluster_identifier     = "${var.project_name}-docdb-${local.aws_region}"
  master_username        = var.docdb_mongo_username
  master_password        = var.docdb_mongo_password
  db_subnet_group_name   = aws_docdb_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  #global_cluster_identifier = local.docdb_global_cluster.id
}

resource "aws_docdb_cluster_instance" "primary" {
  engine             = local.docdb_global_cluster.engine
  identifier         = "${var.project_name}-docdb-${local.aws_region}-instance"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = "db.t3.medium"
}


# logs for msk
resource "aws_cloudwatch_log_group" "this" {
  name = "${var.project_name}-ecs-logs"
}
