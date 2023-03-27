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
data "terraform_remote_state" "region" {
  backend = "local"
  config = {
    path = "../1-region/terraform.tfstate"
  }
}

# local variables that declare what we need
locals {
  # reference the state as global
  region = data.terraform_remote_state.region.outputs

  # variables that we need from the remote state
  aws_region     = local.region.aws.aws_region
  vpc_subnet_ids = local.region.vpc.private_subnets
  vpc_id         = local.region.vpc.vpc_id

  # local references
  kafka_version = "3.2.0"
}

provider "aws" {
  region = local.aws_region
}

# create custom security group kafka
resource "aws_security_group" "this" {
  name   = "${var.project_name}-sg-msk"
  vpc_id = local.vpc_id
  ingress {
    description = "TLS from VPC"
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

# custom configuration for kafka cluster
resource "aws_msk_configuration" "this" {
  kafka_versions = [local.kafka_version]
  name           = "${var.project_name}-configuration"

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
  cluster_name           = var.project_name
  kafka_version          = local.kafka_version
  number_of_broker_nodes = 3
  broker_node_group_info {
    instance_type  = "kafka.t3.small"
    client_subnets = local.vpc_subnet_ids
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

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
    }
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
  name = "${var.project_name}-msk-logs"
}

