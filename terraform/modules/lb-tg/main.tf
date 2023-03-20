# USAGE:
# This module creates a target group and a load balancer for the target group
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

# load balancer 
resource "aws_lb_target_group" "this" {
  name                 = "${var.project.name}-target-group"
  vpc_id               = var.vpc.id
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 5

  health_check {
    enabled             = true
    path                = var.tg.hc.path
    protocol            = var.tg.hc.protocol
    healthy_threshold   = var.tg.hc.healthy_threshold
    unhealthy_threshold = var.tg.hc.unhealthy_threshold
    interval            = var.tg.hc.interval
    matcher             = var.tg.hc.matcher
  }
}

resource "aws_lb" "this" {
  name               = "${var.project.name}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.lb.security_group_ids
  subnets            = var.vpc.subnets
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

