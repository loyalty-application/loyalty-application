terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.8.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

# create a mongodb cluster
resource "mongodbatlas_advanced_cluster" "this" {
  project_id   = var.atlas.project_id
  name         = var.atlas.project_name
  cluster_type = "REPLICASET"
  disk_size_gb = 10

  replication_specs {
    region_configs {
      electable_specs {
        instance_size = "M10"
        node_count    = 3
      }
      provider_name = "AWS"
      priority      = 7
      region_name   = var.atlas.project_region
      auto_scaling {
        disk_gb_enabled = false
        compute_enabled = false
      }
    }
  }

  #termination_protection_enabled = true
}

# atlas automatically provisions a network peering container when you create a cluster
# https://www.mongodb.com/docs/atlas/security-vpc-peering/
# https://registry.terraform.io/providers/mongodb/mongodbatlas/latest/docs/resources/network_container
data "mongodbatlas_network_containers" "this" {
  provider_name = "AWS"
  project_id    = mongodbatlas_advanced_cluster.this.project_id
}

# create a mongodb atlas network peering
resource "mongodbatlas_network_peering" "this" {
  provider_name = "AWS"
  container_id  = data.mongodbatlas_network_containers.this.results[0].id
  project_id    = var.atlas.project_id

  aws_account_id       = var.aws.account_id
  accepter_region_name = replace(upper(var.aws.region), "/-/", "_")

  # vpc_id and cidr_block of vpc you want to peer with on aws
  vpc_id                 = var.vpc.id
  route_table_cidr_block = var.vpc.cidr

  lifecycle {
    ignore_changes = [
      accepter_region_name
    ]
  }
}

# add your aws vpc's cidr to the access list
resource "mongodbatlas_project_ip_access_list" "this" {
  project_id = var.atlas.project_id
  cidr_block = var.vpc.cidr
}

# automatically accept the peering connection request
resource "aws_vpc_peering_connection_accepter" "this" {
  vpc_peering_connection_id = mongodbatlas_network_peering.this.connection_id
  auto_accept               = true
}

# check for aws vpc peering connections on aws
# https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVpcPeeringConnections.html
data "aws_vpc_peering_connections" "this" {
  filter {
    name   = "accepter-vpc-info.vpc-id"
    values = [var.vpc.id]
  }
  filter {
    name   = "accepter-vpc-info.cidr-block"
    values = [var.vpc.cidr]
  }

  depends_on = [
    aws_vpc_peering_connection_accepter.this
  ]
}

# find the route_table for the subnet we're using for the peering
data "aws_route_table" "this" {
  subnet_id = var.vpc.subnets[0]
}

# create route on aws_route_table for atlas vpc
resource "aws_route" "this" {
  route_table_id            = data.aws_route_table.this.id
  vpc_peering_connection_id = data.aws_vpc_peering_connections.this.ids[0]
  destination_cidr_block    = data.mongodbatlas_network_containers.this.results[0].atlas_cidr_block
}

# create user for applications to access database
resource "mongodbatlas_database_user" "this" {
  project_id         = var.atlas.project_id
  username           = var.atlas.username
  password           = var.atlas.password
  auth_database_name = "admin"
  roles {
    database_name = "admin"
    role_name     = "atlasAdmin"
  }
  scopes {
    name = var.atlas.project_name
    type = "CLUSTER"
  }
}
