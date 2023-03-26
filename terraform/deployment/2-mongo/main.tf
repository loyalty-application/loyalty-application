
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
  source = "../../modules/mongo"
  aws    = var.aws
  atlas  = var.atlas
  vpc    = merge({ subnets = var.vpc.public_subnet_ids }, var.vpc)
}


