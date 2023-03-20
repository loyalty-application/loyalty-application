
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.8.1"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws.region
}
provider "mongodbatlas" {}

module "mongo" {
  source         = "../modules/mongo"
  aws_account_id = var.aws.account_id
  cluster = {
    project_region = var.atlas.project_region
    project_id     = var.atlas.project_id
  }
  cluster_network = {
    vpc_id            = var.vpc.id
    vpc_cidr          = var.vpc.cidr
    public_subnet_ids = var.vpc.public_subnets
  }
}
