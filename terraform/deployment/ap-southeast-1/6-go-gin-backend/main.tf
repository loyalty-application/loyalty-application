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
data "terraform_remote_state" "global" {
  backend = "local"
  config = {
    path = "../../global/terraform.tfstate"
  }
}
# use state from region
data "terraform_remote_state" "region" {
  backend = "local"
  config = {
    path = "../1-region/terraform.tfstate"
  }
}

# use state from msk
data "terraform_remote_state" "msk" {
  backend = "local"
  config = {
    path = "../2-kafka-msk/terraform.tfstate"
  }
}


# local variables that declare what we need
locals {
  # reference the state as global
  global = data.terraform_remote_state.global.outputs
  region = data.terraform_remote_state.region.outputs
  msk    = data.terraform_remote_state.msk.outputs

  # variables that we need from the remote state
  route53_zone_id              = local.global.dns.route53_zone.zone_id
  iam_ecs_instance_profile_arn = local.global.iam.ecs.instance_profile.arn
  iam_ecs_instance_role_arn    = local.global.iam.ecs.instance_role.arn
  iam_ecs_service_role_arn     = local.global.iam.ecs.service_role.arn

  aws_region            = local.region.aws.aws_region
  vpc_subnet_ids        = local.region.vpc.private_subnets
  vpc_id                = local.region.vpc.vpc_id
  key_pair_name         = local.region.key_pairs.names[0]
  certificate_arn       = local.region.certificate.certificate_arn
  docdb_host            = local.region.docdb.cluster.endpoint
  docdb_username        = local.region.docdb.cluster.master_username
  docdb_password        = local.region.docdb.cluster.master_password
  msk_connection_string = local.msk.msk.bootstrap_brokers
}

provider "aws" {
  region = local.aws_region
}

# create security groups
resource "aws_security_group" "this" {
  name   = "${var.project_name}-sg"
  vpc_id = local.vpc_id
  ingress {
    description = "allow all"
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

# ecs using ec2
module "ecs_ec2" {
  source = "../../../modules/ecs-ec2-cluster"
  # dependencies from region
  vpc = {
    subnets = local.vpc_subnet_ids,
    id      = local.vpc_id
  }
  key_pair = {
    name = local.key_pair_name
  }
  iam = {
    instance_profile_arn = local.iam_ecs_instance_profile_arn
    instance_role_arn    = local.iam_ecs_instance_role_arn
    service_role_arn     = local.iam_ecs_service_role_arn
  }

  # dependency for this deployment
  project = {
    name = var.project_name
  }
  ecs = merge(
    var.ecs,
    { security_group_ids = [aws_security_group.this.id] }
  )
}

# create lb and tg for ecs cluster
module "lb_tg" {
  source = "../../../modules/ecs-ec2-lb-tg"
  vpc = {
    subnets = local.vpc_subnet_ids,
    id      = local.vpc_id
  }
  ecs         = { asg = { id = module.ecs_ec2.asg.id } }
  project     = { name = var.project_name }
  tg          = var.tg
  lb          = { security_group_ids = [aws_security_group.this.id] }
  certificate = { arn = local.certificate_arn }
}


locals {
  container_image = "docker.io/loyaltyapplication/go-gin-backend:latest"
  container_port  = 8080
}

# ecs task definition
resource "aws_ecs_task_definition" "this" {
  family = "${var.project_name}-task-def"
  container_definitions = jsonencode([
    {
      name              = "${var.project_name}-container"
      image             = local.container_image
      essential         = true
      memoryReservation = 256
      portMappings = [
        {
          containerPort = local.container_port
          hostPort      = 0
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = local.aws_region
          awslogs-stream-prefix = var.project_name
        }
      }
      environment = [
        { name = "SERVER_PORT", value = "8080" },
        { name = "JWT_SECRET", value = var.JWT_SECRET },
        { name = "MONGO_HOST", value = local.docdb_host },
        { name = "MONGO_USERNAME", value = local.docdb_username },
        { name = "MONGO_PASSWORD", value = local.docdb_password },
        { name = "KAFKA_BOOTSTRAP_SERVER", value = local.msk_connection_string }
      ]
    }
  ])
}

# ecs service
resource "aws_ecs_service" "this" {
  name                 = "${var.project_name}-service"
  cluster              = module.ecs_ec2.cluster.id
  task_definition      = aws_ecs_task_definition.this.arn
  iam_role             = local.iam_ecs_service_role_arn
  desired_count        = 1
  force_new_deployment = true

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = module.ecs_ec2.cp.name
  }

  # remove this if you don't need lb-tg
  load_balancer {
    target_group_arn = module.lb_tg.tg.arn
    container_name   = "${var.project_name}-container"
    container_port   = local.container_port
  }
}


# add CNAME record for route53
resource "aws_route53_record" "this" {
  zone_id = local.route53_zone_id
  name    = var.project_name
  type    = "CNAME"
  ttl     = 3600
  records = [module.lb_tg.lb.dns_name]
}

# logs for go-gin-backend
resource "aws_cloudwatch_log_group" "this" {
  name = "${var.project_name}-logs"
}
