terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

# local variables
locals {
  container_port = 8080
}

# ecs task definition
resource "aws_ecs_task_definition" "this" {
  family                = "${var.project.name}-task-def"
  container_definitions = <<TASK_DEFINITION
  [
      {
        "memoryReservation": 256,
        "environment": [
            {"name": "SERVER_PORT", "value":"${local.container_port}"},
            {"name": "MONGO_USERNAME", "value":"${var.ENV["MONGO_USERNAME"]}"},
            {"name": "MONGO_PASSWORD", "value":"${var.ENV["MONGO_PASSWORD"]}"},
            {"name": "MONGO_HOST", "value":"${var.ENV["MONGO_HOST"]}"},
            {"name": "JWT_SECRET", "value":"${var.ENV["JWT_SECRET"]}"},
            {"name": "KAFKA_BOOTSTRAP_SERVER","value":"${var.ENV["KAFKA_BOOTSTRAP_SERVER"]}" }
        ],
        "essential": true,
        "image": "docker.io/loyaltyapplication/go-gin-backend:latest",
        "name": "${var.project.name}-container",
        "portMappings": [
          {
            "containerPort": ${local.container_port},
            "hostPort": 0
          }
        ]
      }
    ]
    TASK_DEFINITION
}

# ecs service
resource "aws_ecs_service" "ecs_service" {
  name                 = "${var.project.name}-service"
  cluster              = var.ecs.cluster.id
  task_definition      = aws_ecs_task_definition.this.arn
  iam_role             = var.iam.service_role_arn
  desired_count        = 1
  force_new_deployment = true
  load_balancer {
    target_group_arn = var.tg.arn
    container_name   = "${var.project.name}-container"
    container_port   = local.container_port
  }
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.cp.name
  }
}
