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
# HIGH ===============
# advertised.listeners
# broker.id
min.insync.replicas=1
# node.id
offsets.topic.replication.factor=2
# process.roles
transaction.state.log.min.isr=1
transaction.state.log.replication.factor=1
# MEDIUM ===============
default.replication.factor=3
group.initial.rebalance.delay.ms=0
  PROPERTIES
}

# msk cluster deployment
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
        enabled_in_broker = true
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

# logs for msk
resource "aws_cloudwatch_log_group" "this" {
  name = "${local.project_name}-broker-logs"
}

