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

variable "network_subnet_private_cidrs" {
  type = list(string)
}

variable "network_subnet_availability_zones" {
  type = list(string)
}

variable "network_vpc_cidr" {
  type = string
}

module "network" {
  source                            = "./modules/network"
  network_vpc_cidr                  = var.network_vpc_cidr
  network_subnet_availability_zones = var.network_subnet_availability_zones
  network_subnet_private_cidrs      = var.network_subnet_private_cidrs

}
