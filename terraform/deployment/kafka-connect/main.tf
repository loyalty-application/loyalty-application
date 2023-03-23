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
    { subnets = var.vpc.public_subnet_ids },
    var.vpc
  )
  ecs = merge(
    { security_group_ids = [aws_security_group.this.id] },
    var.ecs
  )

  key_pair = var.key_pair
  iam      = var.iam
}

# local variables
locals {
  container_port  = 8083
  container_name  = "${var.project.name}-container"
  container_image = "cnfldemos/cp-server-connect-datagen:0.6.0-7.3.0"
}

# ecs task definition
resource "aws_ecs_task_definition" "this" {

  family = "${var.project.name}-task-def"

  volume {
    name = "efsVolume"
    efs_volume_configuration {
      transit_encryption = "DISABLED"
      file_system_id     = var.efs.file_system_id
      root_directory     = "/"
    }
  }
  container_definitions = jsonencode([
    {
      name              = local.container_name
      image             = local.container_image
      essential         = true
      memoryReservation = 256
      privileged        = true
      portMappings = [
        {
          containerPort = local.container_port
          hostPort      = 0
        }
      ]
      environment = [
        for k, v in var.ENV : { name = k, value = v }
      ]
      command = [
        # chmod 777 /data && chmod 777 /data/* && 
        "sh", "-c", "chmod 777 /data && chmod 777 /data/* && confluent-hub install --no-prompt jcustenborder/kafka-connect-spooldir:2.0.65 && (/etc/confluent/docker/run &) && tail -f /dev/null"
      ]
      mountPoints : [
        {
          sourceVolume  = "efsVolume",
          containerPath = "/data",
        }
      ]
    }
  ])
}

# ecs service
resource "aws_ecs_service" "ecs_service" {
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
