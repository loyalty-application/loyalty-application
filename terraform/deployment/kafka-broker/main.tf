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
  container_name  = "broker2"
  container_image = "confluentinc/cp-kafka:latest"
}

## kafka broker 2
#broker2:
#image: confluentinc/cp-kafka:latest
#container_name: broker2
#depends_on:
#- broker
#ports:
#- "9093:9092"
#- "9102:9101"
#environment:
#KAFKA_BROKER_ID: 2
#KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
#KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://broker2:29092,PLAINTEXT_HOST://localhost:9093
#KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 2
#KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
#KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
#KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
#KAFKA_JMX_PORT: 9101
#KAFKA_JMX_HOSTNAME: localhost
#KAFKA_PROCESS_ROLES: 'broker,controller'
#KAFKA_NODE_ID: 2
#KAFKA_CONTROLLER_QUORUM_VOTERS: '1@broker:29093,2@broker2:29093,3@broker3:29093'
#KAFKA_LISTENERS: 'PLAINTEXT://broker2:29092,CONTROLLER://broker2:29093,PLAINTEXT_HOST://0.0.0.0:9092'
#KAFKA_INTER_BROKER_LISTENER_NAME: 'PLAINTEXT'
#KAFKA_CONTROLLER_LISTENER_NAMES: 'CONTROLLER'
#KAFKA_LOG_DIRS: '/tmp/kraft-combined-logs'
#KAFKA_DEFAULT_REPLICATION_FACTOR: 3
#KAFKA_MIN_INSYNC_REPLICAS: 1
#restart: always
#volumes:
#- ./update_run.sh:/tmp/update_run.sh
#command: ""
#profiles: [ "kafka" ]

# ecs task definition
resource "aws_ecs_task_definition" "this" {
  family = "${var.project.name}-task-def"
  container_definitions = jsonencode([
    {
      name              = local.container_name
      image             = local.container_image
      essential         = true
      memoryReservation = 256
      portMappings = [
        {
          containerPort = 9092
          hostPort      = 9093
        },
        {
          containerPort = 9101
          hostPort      = 9102
        }
      ],
      volumes = [],
      environment = [
        for k, v in var.ENV : { name = k, value = v }
      ],
      command = ["bash", "-c", "sed -i '/KAFKA_ZOOKEEPER_CONNECT/d' /etc/confluent/docker/configure && sed -i 's/cub zk-ready/echo ignore zk-ready/' /etc/confluent/docker/ensure && echo \"kafka-storage format --ignore-formatted --cluster-id=NqnEdODVKkiLTfJvqd1uqQ== -c /etc/kafka/kafka.properties\" >> /etc/confluent/docker/ensure && /etc/confluent/docker/run"],
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
