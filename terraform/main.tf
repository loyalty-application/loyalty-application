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


# Network Setup
module "network" {
  source                            = "./modules/network"
  project_name                      = var.project_name
  project_domain                    = var.project_domain
  network_vpc_cidr                  = var.network_vpc_cidr
  network_subnet_availability_zones = var.network_subnet_availability_zones
  network_subnet_private_cidrs      = var.network_subnet_private_cidrs
  network_subnet_public_cidrs       = var.network_subnet_public_cidrs
  network_nameservers               = var.network_nameservers

  aws_lb_dns_name = module.ecs_ec2.aws_lb_dns_name
}



# ECR Setup
module "ecr" {
  source   = "./modules/ecr"
  ecr_name = var.ecr_name
}


# ecs using ec2
module "ecs_ec2" {
  source            = "./modules/ecs_ec2"
  project_name      = var.project_name
  aws_region        = "ap-southeast-1"
  ec2_ami           = var.ec2_ami
  ec2_instance_type = var.ec2_instance_type

  # network resources
  network_vpc_id          = module.network.network_vpc_id
  network_security_groups = [module.network.network_security_group_id]
  network_subnets         = module.network.network_subnets_public

  # change this to private subnet when not in testing
  ecs_asg_min_size         = var.ecs_asg_min_size
  ecs_asg_max_size         = var.ecs_asg_max_size
  ecs_asg_desired_capacity = var.ecs_asg_desired_capacity
  ecs_asg_hc_grace_period  = var.ecs_asg_hc_grace_period
  ecs_asg_hc_type          = var.ecs_asg_hc_type

  health_check_path   = "/api/v1/health"
  ssl_certificate_arn = module.network.certificate_arn

  MONGO_HOST     = var.MONGO_HOST
  MONGO_USERNAME = var.MONGO_USERNAME
  MONGO_PASSWORD = var.MONGO_PASSWORD

  key_pair_name       = var.key_pair_name
  key_pair_public_key = var.key_pair_public_key

  iam_ecs_instance_role    = "${var.project_name}-ecs-instance-profile"
  iam_ecs_service_role     = "${var.project_name}-ecs-service-role"
  iam_ecs_instance_profile = "${var.project_name}-ecs-instance-profile"
}



