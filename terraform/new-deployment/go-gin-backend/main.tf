locals {
  project_name = "go-gin-backend"
}

resource "aws_ecs_task_definition" "this" {
  family                = "${local.project_name}-task-definition"
  container_definitions = <<TASK_DEFINITION
  [
      {
        "memoryReservation": 256,
        "environment": [
            {"name": "MONGO_USERNAME", "value":"${var.MONGO_USERNAME}"},
            {"name": "MONGO_PASSWORD", "value":"${var.MONGO_PASSWORD}"},
            {"name": "MONGO_HOST", "value":"${var.MONGO_HOST}"},
            {"name": "SERVER_PORT", "value":"8080"},
            {"name": "JWT_SECRET", "value":"SOMEJWTSECRET"},
            {"name": "KAFKA_BOOTSTRAP_SERVER","value":"kafka:9092" }
        ],
        "essential": true,
        "image": "docker.io/loyaltyapplication/go-gin-backend:latest",
        "name": "${local.project_name}-container",
        "portMappings": [
          {
            "containerPort": 8080,
            "hostPort": 0
          }
        ]
      }
    ]
    TASK_DEFINITION
}

resource "aws_ecs_service" "this" {
  name                               = local.project_name
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = 1
  force_new_deployment               = true
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.cluster_capacity_provider_name
  }
}

