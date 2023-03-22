terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}


# ecs task definition
resource "aws_ecs_task_definition" "this" {
  family                = "${var.project.name}-task-def"
  container_definitions = var.ecs.task.definition
}

# ecs service
resource "aws_ecs_service" "this" {
  name                 = "${var.project.name}-service"
  cluster              = var.ecs.cluster.id
  task_definition      = aws_ecs_task_definition.this.arn
  iam_role             = var.iam.service_role_arn ? var.iam.service_role_arn : null
  desired_count        = 1
  force_new_deployment = true

  dynamic "load_balancer" {
    for_each         = [var.tg.arg]
    target_group_arn = var.tg.arn
    container_name   = "${var.project.name}-container"
    container_port   = var.ecs.task.container_port
  }
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.cp.name
  }
}
