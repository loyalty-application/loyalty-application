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
# use state from region
data "terraform_remote_state" "region" {
  backend = "local"
  config = {
    path = "../1-region/terraform.tfstate"
  }
}

# use state from msk
data "terraform_remote_state" "msk" {
  backend = "local"
  config = {
    path = "../2-kafka-msk/terraform.tfstate"
  }
}

# local variables that declare what we need
locals {
  # reference the state as global
  global = data.terraform_remote_state.global.outputs
  region = data.terraform_remote_state.region.outputs
  msk    = data.terraform_remote_state.msk.outputs

  # variables that we need from the remote state
  iam_ecs_instance_profile_arn = local.global.iam.ecs.instance_profile.arn
  iam_ecs_instance_role_arn    = local.global.iam.ecs.instance_role.arn
  iam_ecs_service_role_arn     = local.global.iam.ecs.service_role.arn

  aws_region            = local.region.aws.aws_region
  vpc_subnet_ids        = local.region.vpc.private_subnets
  vpc_id                = local.region.vpc.vpc_id
  key_pair_name         = local.region.key_pairs.names[0]
  efs_file_system_id    = local.region.efs.file_system.id
  msk_connection_string = local.msk.msk.bootstrap_brokers
}

# create security groups
resource "aws_security_group" "this" {
  name   = "${var.project_name}-sg"
  vpc_id = local.vpc_id
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

provider "aws" {
  region = local.aws_region
}

# ecs using ec2
module "ecs_ec2" {
  source = "../../../modules/ecs-ec2-cluster"
  # dependencies from region
  vpc = {
    subnets = local.vpc_subnet_ids,
    id      = local.vpc_id
  }
  key_pair = {
    name = local.key_pair_name
  }
  iam = {
    instance_profile_arn = local.iam_ecs_instance_profile_arn
    instance_role_arn    = local.iam_ecs_instance_role_arn
    service_role_arn     = local.iam_ecs_service_role_arn
  }

  # dependency for this deployment
  project = {
    name = var.project_name
  }
  ecs = merge(
    var.ecs,
    { security_group_ids = [aws_security_group.this.id] }
  )
}

## ecs task definition
#resource "aws_ecs_task_definition" "init_kafka" {
#family = "init-kafka-task-def"
#volume {
#name = "efsVolume"
#efs_volume_configuration {
#transit_encryption = "DISABLED"
#file_system_id     = local.efs_file_system_id
#root_directory     = "/"
#}
#}
#network_mode = "awsvpc"
#container_definitions = jsonencode([
#{
#name              = "init-kafka-container"
#image             = "docker.io/loyaltyapplication/init-kafka:latest"
#memoryReservation = 256
#logConfiguration = {
#logDriver = "awslogs",
#options = {
#awslogs-group         = aws_cloudwatch_log_group.this.name
#awslogs-region        = local.aws_region
#awslogs-stream-prefix = var.project_name
#}
#}
#environment = [
#{ name = "BOOTSTRAP_SERVERS", value = local.msk_connection_string },
#{ name = "CONNECTOR_HOST", value = var.CONNECTOR_HOST }
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

## onetime tasks
#data "aws_ecs_task_execution" "this" {
#cluster         = module.ecs_ec2.cluster.id
#task_definition = aws_ecs_task_definition.init_kafka.arn
#desired_count   = 1
#network_configuration {
#subnets         = local.vpc_subnet_ids
#security_groups = [aws_security_group.this.id]
#}
#capacity_provider_strategy {
#base              = 1
#weight            = 100
#capacity_provider = module.ecs_ec2.cp.name
#}
#depends_on = [
#module.ecs_ec2.cluster
#]
#}

locals {
  kafka_connect_task_definition = [
    {
      name              = var.project_name
      image             = "docker.io/loyaltyapplication/kafka-connect:latest"
      memoryReservation = 256
      network_mode      = "awsvpc"
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = local.aws_region
          awslogs-stream-prefix = var.project_name
        }
      }
      environment = concat([for k, v in var.KAFKA_CONNECT_ENV : { name = k, value = v }],
        [
          { name = "APP_ENV", value = "release" },
          { name = "CONNECT_BOOTSTRAP_SERVERS", value = local.msk_connection_string },
          { name = "CONNECT", value = "SFTP_NODE" },
          { name = "SFTP_HOST", value = var.SFTP_HOST },
          { name = "SFTP_USERNAME", value = var.SFTP_USERNAME },
          { name = "SFTP_PASSWORD", value = var.SFTP_PASSWORD },
      ])
      mountPoints : [
        {
          sourceVolume  = "efsVolume",
          containerPath = "/data",
        }
      ]
      command = [
        # chmod 777 /data && chmod 777 /data[> && 
        "sh", "-c", "echo $SFTP_HOST && (rm /data/unprocessed/*.PROCESSING &) && (./run.sh 2021-09-20 &) && (/etc/confluent/docker/run &) && tail -f /dev/null"
      ]
    },
    {
      name              = "init-kafka-container"
      image             = "docker.io/loyaltyapplication/init-kafka:latest"
      links             = [var.project_name]
      memoryReservation = 256
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = local.aws_region
          awslogs-stream-prefix = var.project_name
        }
      }
      environment = [
        { name = "BOOTSTRAP_SERVERS", value = local.msk_connection_string },
        { name = "CONNECTOR_HOST", value = var.project_name }
      ]
      mountPoints : [
        {
          sourceVolume  = "efsVolume",
          containerPath = "/data",
        }
      ]
    }
  ]

}

# ----------------------------------------------------------------------
# ecs task definition
resource "aws_ecs_task_definition" "kafka_connect" {
  family = "${var.project_name}-task-def"
  volume {
    name = "efsVolume"
    efs_volume_configuration {
      transit_encryption = "DISABLED"
      file_system_id     = local.efs_file_system_id
      root_directory     = "/"
    }
  }
  container_definitions = jsonencode(local.kafka_connect_task_definition)
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
  name                = "${var.project_name}-cron-rule"
  description         = "Cron Job"
  schedule_expression = "rate(5 minutes)"
  #schedule_expression = "rate(12 hours)"
}

# cloudwatch event target
resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  target_id = "${var.project_name}-job"
  arn       = module.ecs_ec2.cluster.arn
  rule      = aws_cloudwatch_event_rule.this.name
  role_arn  = aws_iam_role.ecs_events.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.kafka_connect.arn
  }

  #input = jsonencode({
  #containerOverrides = [
  #{
  #name = var.project_name,

  #}
  #]
  #})

  input = jsonencode({
    containerOverrides = local.kafka_connect_task_definition
  })
  #input = jsonencode({
  #containerOverrides = [
  #{
  #name = "go-sftp-txn",
  #command = [
  #"2021-08-27"
  #]
  #}
  #]
  #})
}


resource "aws_cloudwatch_log_group" "this" {
  name = "${var.project_name}-logs"
}
