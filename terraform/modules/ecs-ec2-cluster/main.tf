# USAGE:
# This module creates an ECS Cluster with a EC2 Capacity Provider, an Auto Scaling Group, along with a launch template
# You will need pre-create a target group for it to attach to (note that this module does not do the creating, it will only attach the target group for you)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

# create ecs cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project.name}-cluster"
}

# create launch template for asg
resource "aws_launch_template" "this" {
  image_id    = data.aws_ami.amazon-linux-2.id
  name_prefix = "${var.project.name}-lc-"

  instance_type          = var.ecs.instance_type
  vpc_security_group_ids = var.ecs.security_group_ids
  key_name               = var.key_pair.name

  user_data = base64encode(templatefile("${path.module}/user-data.tpl", {
    ECS_CLUSTER = aws_ecs_cluster.this.name
  }))

  iam_instance_profile {
    arn = var.iam.instance_profile_arn
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      key   = "AmazonECSManaged"
      value = true
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

# create asg
resource "aws_autoscaling_group" "this" {
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  name                = "${var.project.name}-asg"
  vpc_zone_identifier = var.vpc.subnets

  desired_capacity = var.ecs.asg.desired_capacity
  min_size         = var.ecs.asg.min_size
  max_size         = var.ecs.asg.max_size

  # prevents terraform from removing this tag
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_capacity_provider" "this" {
  name = "${var.project.name}-asg-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.this.arn
    #managed_scaling {
    #maximum_scaling_step_size = 1000
    #minimum_scaling_step_size = 1
    #status                    = "ENABLED"
    #target_capacity           = 10
    #}
  }

}

# assign the capacity provider to the cluster
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.this.name]
}

