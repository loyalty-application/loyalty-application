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
    { subnets = var.vpc.private_subnet_ids },
    var.vpc
  )
  ecs = merge(
    { security_group_ids = [aws_security_group.this.id] },
    var.ecs
  )

  key_pair = var.key_pair
  iam      = var.iam
}

# ecs task definition
resource "aws_ecs_task_definition" "init_kafka" {
  family = "init-kafka-task-def"
  volume {
    name = "efsVolume"
    efs_volume_configuration {
      transit_encryption = "DISABLED"
      file_system_id     = var.efs.file_system_id
      root_directory     = "/"
    }
  }
  network_mode = "awsvpc"
  container_definitions = jsonencode([
    {
      name              = "init-kafka-container"
      image             = "docker.io/loyaltyapplication/init-kafka:latest"
      memoryReservation = 256
      environment = [
        for k, v in var.ENV : { name = k, value = v }
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

# onetime tasks
data "aws_ecs_task_execution" "this" {
  cluster         = module.ecs_ec2.cluster.id
  task_definition = aws_ecs_task_definition.init_kafka.arn
  desired_count   = 1
  network_configuration {
    subnets         = var.vpc.private_subnet_ids
    security_groups = [aws_security_group.this.id]
  }
  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = module.ecs_ec2.cp.name
  }
}

# ----------------------------------------------------------------------
# ecs task definition
resource "aws_ecs_task_definition" "go_sftp_txn" {
  family = "go-sftp-txn-task-def"
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
      name              = "go-sftp-txn"
      image             = "docker.io/loyaltyapplication/go-sftp-txn:latest"
      memoryReservation = 256
      environment = [
        for k, v in var.ENV : { name = k, value = v }
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

# iam role
resource "aws_iam_role" "ecs_events" {
  name               = "ecs_events"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# iam policy
resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  name   = "ecs_events_run_task_with_any_role"
  role   = aws_iam_role.ecs_events.id
  policy = data.aws_iam_policy_document.ecs_events_run_task_with_any_role.json
}

# cloudwatch event rule
resource "aws_cloudwatch_event_rule" "this" {
  name                = "go-sftp-txn-cron-rule"
  description         = "Cron Job to run go-sftp-txn"
  schedule_expression = "rate(30 minutes)"
}


# cloudwatch event target
resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  target_id = "go-sftp-txn-job"
  arn       = module.ecs_ec2.cluster.arn
  rule      = aws_cloudwatch_event_rule.this.name
  role_arn  = aws_iam_role.ecs_events.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.go_sftp_txn.arn
  }
  input = jsonencode({
    containerOverrides = [
      {
        name = "go-sftp-txn",
        command = [
          "2021-08-27"
        ]
      }
    ]
  })

}

