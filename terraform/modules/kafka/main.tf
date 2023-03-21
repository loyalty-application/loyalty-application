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

locals {
  project_name  = "loyalty-application"
  kafka_version = "3.2.0"
}

resource "aws_security_group" "this" {
  name   = "${local.project_name}-sg"
  vpc_id = var.vpc.id
  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
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

resource "aws_msk_configuration" "this" {
  kafka_versions = [local.kafka_version]
  name           = "${local.project_name}-configuration"

  server_properties = <<PROPERTIES
  auto.create.topics.enable=true
  default.replication.factor=3
  min.insync.replicas=1
  num.io.threads=8
  num.network.threads=5
  num.partitions=20
  num.replica.fetchers=2
  replica.lag.time.max.ms=30000
  socket.receive.buffer.bytes=102400
  socket.request.max.bytes=104857600
  socket.send.buffer.bytes=102400
  unclean.leader.election.enable=true
  zookeeper.session.timeout.ms=18000
  group.initial.rebalance.delay.ms=0
  PROPERTIES
}

resource "aws_msk_cluster" "this" {
  # required
  cluster_name           = local.project_name
  kafka_version          = local.kafka_version
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type  = "kafka.t3.small"
    client_subnets = var.vpc.subnets
    storage_info {
      ebs_storage_info {
        volume_size = 10
      }
    }
    security_groups = [aws_security_group.this.id]
  }

  configuration_info {
    arn      = aws_msk_configuration.this.arn
    revision = aws_msk_configuration.this.latest_revision
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = false
      }
      node_exporter {
        enabled_in_broker = false
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.this.name
      }
    }
  }


}

resource "aws_cloudwatch_log_group" "this" {
  name = "${local.project_name}-broker-logs"
}

