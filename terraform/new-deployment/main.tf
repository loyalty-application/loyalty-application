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
  region = var.aws_config.region
}
provider "mongodbatlas" {}

# rename as needed for project
locals {
  project_names = ["loyalty", "nextjs-frontend", "go-gin-backend", "go-worker-node", "go-sftp-txn"]
}

# main vpc for all deployments
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = "${local.project_names[0]}-vpc"
  cidr                 = var.vpc.cidr
  azs                  = var.vpc.azs
  private_subnets      = var.vpc.private_subnets
  public_subnets       = var.vpc.public_subnets
  enable_nat_gateway   = false
  enable_vpn_gateway   = false
  enable_dhcp_options  = true
  enable_dns_hostnames = true
}

# find recommended image
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

# create asg security-group
module "autoscaling_sg" {
  source              = "terraform-aws-modules/security-group/aws"
  version             = "~> 4.0"
  name                = "${local.project_names[2]}-asg-sg"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp"]
  egress_rules        = ["all-all"]
}

# create asg
module "autoscaling" {
  source          = "terraform-aws-modules/autoscaling/aws"
  version         = "~> 6.5"
  instance_type   = "t2.micro"
  name            = "${local.project_names[2]}-asg"
  image_id        = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  security_groups = [module.autoscaling_sg.security_group_id]
  user_data = base64encode(
    templatefile(
      "${path.module}/user_data.tpl",
      {
        ECS_CLUSTER = module.ecs.cluster_name,
        TG_ARN      = module.alb.lb_arn
      }
    )
  )
  create_iam_instance_profile = true
  iam_role_name               = "iam_ecs_role"
  iam_role_description        = "ECS role"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "EC2"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1

  # https://github.com/hashicorp/terraform-provider-aws/issues/12582
  autoscaling_group_tags = {
    AmazonECSManaged = true
  }
}


# ecs deployment
module "ecs" {
  source       = "terraform-aws-modules/ecs/aws"
  cluster_name = local.project_names[2]
  autoscaling_capacity_providers = {
    ("${local.project_names[2]}-asg") = {
      auto_scaling_group_arn = module.autoscaling.autoscaling_group_arn
      managed_scaling = {
        maximum_scaling_step_size = 2
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100
      }
    }
  }
}

# ecs service
module "go_gin_backend" {
  source                         = "./go-gin-backend"
  cluster_id                     = module.ecs.cluster_id
  cluster_capacity_provider_name = module.ecs.autoscaling_capacity_providers["${local.project_names[2]}-asg"].name
}

# create application lb
module "alb" {
  source             = "terraform-aws-modules/alb/aws"
  version            = "~> 8.0"
  name               = "${local.project_names[2]}-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.private_subnets
  security_groups    = [module.autoscaling_sg.security_group_id]
  target_groups = [
    {
      name_prefix          = "ggb-"
      backend_protocol     = "HTTP"
      backend_port         = 8080
      target_type          = "instance"
      deregistration_delay = 5
      health_check = {
        enabled             = true
        path                = "/api/v1/health"
        port                = "traffic-port"
        interval            = 30
        healthy_threshold   = 2
        unhealthy_threshold = 3
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  ]
  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = module.acm.acm_certificate_arn
      target_group_index = 0
    }
  ]
}

# attach asg to tg for lb
resource "aws_autoscaling_attachment" "tg_lb_attachement" {
  autoscaling_group_name = module.autoscaling.autoscaling_group_name
  lb_target_group_arn    = module.alb.target_group_arns[0]
}

module "zones" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "~> 2.0"
  zones = {
    (var.dns.domain_name) = {
      comment = "terraform route53 zone"
    }
  }
}

resource "aws_route53domains_registered_domain" "domain" {
  domain_name = var.dns.domain_name
  name_server {
    name = module.zones.route53_zone_name_servers[var.dns.domain_name][0]
  }
  name_server {
    name = module.zones.route53_zone_name_servers[var.dns.domain_name][1]
  }
  name_server {
    name = module.zones.route53_zone_name_servers[var.dns.domain_name][2]
  }
  name_server {
    name = module.zones.route53_zone_name_servers[var.dns.domain_name][3]
  }

}

module "acm" {
  source      = "terraform-aws-modules/acm/aws"
  version     = "~> 4.0"
  zone_id     = module.zones.route53_zone_zone_id[var.dns.domain_name]
  domain_name = var.dns.domain_name
  subject_alternative_names = [
    "*.${var.dns.domain_name}",
  ]
  wait_for_validation = true
  depends_on = [
    aws_route53domains_registered_domain.domain
  ]
}

module "records" {
  source    = "terraform-aws-modules/route53/aws//modules/records"
  version   = "~> 2.0"
  zone_name = keys(module.zones.route53_zone_zone_id)[0]
  records = [
    {
      type    = "CNAME"
      name    = local.project_names[2]
      records = [module.alb.lb_dns_name]
      ttl     = 5
    }
  ]
  depends_on = [module.zones]
}
