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

## ecs task definition
#resource "aws_ecs_task_definition" "this" {
#family = "${var.project.name}-task-def"
#volume {
#name = "efsVolume"
#efs_volume_configuration {
#transit_encryption = "DISABLED"
#file_system_id     = var.efs.file_system_id
#root_directory     = "/"
#}
#}
#container_definitions = jsonencode([
#{
#name              = local.container_name
#image             = local.container_image
#memoryReservation = 256
##portMappings = [
##{
##containerPort = local.container_port
##hostPort      = 0
##}
##]
#environment = [
#for k, v in var.ENV : { name = k, value = v }
#]
#command = [
#]
#mountPoints : [
#{
#sourceVolume  = "efsVolume",
#containerPath = "/data",
#}
#]
#}
#])
#}


# ecs task definition
resource "aws_ecs_task_definition" "init_kafka" {
  family       = "init-kafka-task-def"
  network_mode = "awsvpc"
  container_definitions = jsonencode([
    {
      name              = "init-kafka-container"
      image             = "docker.io/loyaltyapplication/init-kafka:latest"
      memoryReservation = 256
      environment = [
        for k, v in var.ENV : { name = k, value = v }
      ]
    }
  ])
}

# onetime tasks
data "aws_ecs_task_execution" "this" {
  cluster         = module.ecs_ec2.cluster.id
  task_definition = aws_ecs_task_definition.init_kafka.arn
  desired_count   = 1
  network_configuration {
    subnets         = var.vpc.public_subnet_ids
    security_groups = [aws_security_group.this.id]
  }
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = module.ecs_ec2.cp.name
  }
}

