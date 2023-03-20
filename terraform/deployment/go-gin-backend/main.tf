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

# create security groups
resource "aws_security_group" "this" {
  name   = "${var.project.name}-sg"
  vpc_id = var.vpc.id
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

# create lb and tg for ecs cluster
module "lb_tg" {
  source  = "../../modules/lb-tg"
  project = var.project
  vpc = merge(
    { subnets = var.vpc.public_subnet_ids },
    var.vpc
  )

  tg          = var.tg
  lb          = { security_group_ids = [aws_security_group.this.id] }
  certificate = var.certificate
}

# ecs using ec2
module "ecs_ec2" {
  source  = "../../modules/ecs-ec2"
  project = var.project
  vpc = merge(
    { subnets = var.vpc.public_subnet_ids },
    var.vpc
  )
  ecs = merge(
    { security_group_ids = [aws_security_group.this.id] },
    { tg_arn = module.lb_tg.tg.arn },
    var.ecs
  )
  key_pair = var.key_pair
  iam      = var.iam
}

# local service and task definition
module "ecs_service_task" {
  source  = "./service"
  project = var.project
  iam     = var.iam
  ENV     = var.ENV
  ecs     = { cluster = { id = module.ecs_ec2.cluster.id } }
  tg      = { arn = module.lb_tg.tg.arn }
  cp      = { name = module.ecs_ec2.cp.name }
}

# add CNAME record for route53
resource "aws_route53_record" "this" {
  zone_id = var.dns.zone.id
  name    = var.project.name
  type    = "CNAME"
  ttl     = 5
  records = [module.lb_tg.lb.dns_name]
}
