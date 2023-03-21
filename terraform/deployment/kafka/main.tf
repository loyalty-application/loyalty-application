# USAGE:
# This module creates a kafka cluster
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

module "kafka" {
  source = "../../modules/kafka"
  aws    = var.aws
  vpc    = merge({ subnets = var.vpc.public_subnet_ids }, var.vpc)
}

