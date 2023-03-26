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

# ecs using ec2
module "ecs_ec2" {
  source  = "../../modules/ecs-ec2-cluster"
  project = var.project
  vpc = merge(
    var.vpc,
    { subnets = var.vpc.public_subnet_ids }
  )
  ecs = merge(
    var.ecs,
    { security_group_ids = [aws_security_group.this.id] }
  )

  key_pair = var.key_pair
  iam      = var.iam
}

# create lb and tg for ecs cluster
module "lb_tg" {
  source  = "../../modules/ecs-ec2-lb-tg"
  project = var.project
  vpc = merge(
    { subnets = var.vpc.public_subnet_ids },
    var.vpc
  )
  ecs = { asg = { id = module.ecs_ec2.asg.id } }

  # remove below if you don't need lb-tg
  tg          = var.tg
  lb          = { security_group_ids = [aws_security_group.this.id] }
  certificate = var.certificate
}

locals {
  container_image = "docker.io/loyaltyapplication/go-gin-backend:latest"
  container_port  = 8080
}

# ecs task definition
resource "aws_ecs_task_definition" "this" {
  family = "${var.project.name}-task-def"
  container_definitions = jsonencode([
    {
      name              = "${var.project.name}-container"
      image             = local.container_image
      essential         = true
      memoryReservation = 256
      portMappings = [
        {
          containerPort = local.container_port
          hostPort      = 0
        }
      ],
      environment = [
        for k, v in var.ENV : { name = k, value = v }
      ]
    }
  ])
}

# ecs service
resource "aws_ecs_service" "this" {
  name                 = "${var.project.name}-service"
  cluster              = module.ecs_ec2.cluster.id
  task_definition      = aws_ecs_task_definition.this.arn
  iam_role             = var.iam.service_role_arn
  desired_count        = 1
  force_new_deployment = true

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = module.ecs_ec2.cp.name
  }

  # remove this if you don't need lb-tg
  load_balancer {
    target_group_arn = module.lb_tg.tg.arn
    container_name   = "${var.project.name}-container"
    container_port   = local.container_port
  }
}


# add CNAME record for route53
resource "aws_route53_record" "this" {
  zone_id = var.dns.zone.id
  name    = var.project.name
  type    = "CNAME"
  ttl     = 5
  records = [module.lb_tg.lb.dns_name]
}
