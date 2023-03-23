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


locals {
  container_image = "docker.io/loyaltyapplication/go-worker-node:latest"
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
  desired_count        = 1
  force_new_deployment = true

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = module.ecs_ec2.cp.name
  }

}


