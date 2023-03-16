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
  region = "ap-southeast-1"
}

# Key Pair Setup
module "auth" {
  source              = "./modules/auth"
  key_pair_name       = var.key_pair_name
  key_pair_public_key = var.key_pair_public_key

  iam_ecs_instance_role    = "ecs_instance_role"
  iam_ecs_service_role     = "ecs_service_role"
  iam_ecs_instance_profile = "ecs_instance_profile"

}

# Network Setup
module "network" {
  source                            = "./modules/network"
  project_name                      = var.project_name
  network_vpc_cidr                  = var.network_vpc_cidr
  network_subnet_availability_zones = var.network_subnet_availability_zones
  network_subnet_private_cidrs      = var.network_subnet_private_cidrs
  network_subnet_public_cidrs       = var.network_subnet_public_cidrs
}



# ECR Setup
module "ecr" {
  source   = "./modules/ecr"
  ecr_name = var.ecr_name
}


# ecs using ec2
module "ecs_ec2" {
  source                     = "./modules/ecs_ec2"
  project_name               = var.project_name
  ec2_ami                    = var.ec2_ami
  ec2_instance_type          = var.ec2_instance_type
  ec2_vpc_security_group_ids = [module.network.network_security_group_id]
  ec2_key_pair_name          = module.auth.key_pair_name
  ec2_iam_instance_profile   = module.auth.iam_ecs_instance_profile

  # change this to private subnet when not in testing
  ecs_asg_subnets          = module.network.network_subnets_public
  ecs_asg_min_size         = var.ecs_asg_min_size
  ecs_asg_max_size         = var.ecs_asg_max_size
  ecs_asg_desired_capacity = var.ecs_asg_desired_capacity
  ecs_asg_hc_grace_period  = var.ecs_asg_hc_grace_period
  ecs_asg_hc_type          = var.ecs_asg_hc_type
}
