terraform {
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "1.8.1"
    }

  }
  required_version = ">= 1.2.0"
}
resource "mongodbatlas_advanced_cluster" "mongo_cluster" {
  project_id   = var.cluster.project_id
  name         = "mongo"
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
      region_name   = var.cluster.project_region
      auto_scaling {
        disk_gb_enabled = false
        compute_enabled = false
      }
    }

  }
}


# create an atlas network container
resource "mongodbatlas_network_container" "atlas-network-container" {
  provider_name    = "AWS"
  project_id       = var.cluster.project_id
  atlas_cidr_block = var.cluster_network.vpc_cidr
  region_name      = var.cluster.project_region
}

# create a mongodb atlas network peering
resource "mongodbatlas_network_peering" "atlas-network-peering" {
  container_id           = mongodbatlas_network_container.atlas-network-container.container_id
  project_id             = var.cluster.project_id
  vpc_id                 = var.cluster_network.vpc_id
  accepter_region_name   = var.cluster.project_region
  route_table_cidr_block = var.cluster_network.vpc_cidr

  provider_name  = "AWS"
  aws_account_id = var.aws_account_id
}

resource "mongodbatlas_project_ip_access_list" "atlas-ip-access-list-1" {
  project_id = var.cluster.project_id
  cidr_block = var.cluster_network.vpc_cidr
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = mongodbatlas_network_peering.atlas-network-peering.connection_id
  auto_accept               = true
}

data "aws_vpc_peering_connection" "vpc-peering-conn-ds" {
  vpc_id      = mongodbatlas_network_peering.atlas-network-peering.atlas_vpc_name
  cidr_block  = var.cluster_network.vpc_cidr
  peer_region = var.cluster.project_region
}

#data "aws_route_table" "vpc-public-subnet-1-ds" {
#subnet_id = var.cluster_network.public_subnet_ids[0]
#}

##VPC Peer Device to ATLAS Route Table Association on AWS
#resource "aws_route" "aws_peer_to_atlas_route_1" {
#route_table_id            = data.aws_route_table.vpc-public-subnet-1-ds.id
#vpc_peering_connection_id = data.aws_vpc_peering_connection.vpc-peering-conn-ds.id
#destination_cidr_block    = var.cluster_network.vpc_cidr
#}

resource "mongodbatlas_database_user" "this" {
  username           = "admin"
  password           = "password"
  project_id         = var.cluster.project_id
  auth_database_name = "mongo"

  roles {
    role_name     = "readAnyDatabase"
    database_name = "admin"
  }

  scopes {
    name = "mongo"
    type = "CLUSTER"
  }

}
