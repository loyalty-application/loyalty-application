
data "aws_iam_policy_document" "ecs-service-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "ecs-instance-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ec2 service role
resource "aws_iam_role" "ecs-instance-role" {
  name                  = var.iam_ecs_instance_role
  path                  = "/"
  assume_role_policy    = data.aws_iam_policy_document.ecs-instance-policy.json
  force_detach_policies = true
}
resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = var.iam_ecs_instance_profile
  path = "/"
  role = aws_iam_role.ecs-instance-role.id
}


# ecs service role
resource "aws_iam_role" "ecs-service-role" {
  name                  = var.iam_ecs_service_role
  path                  = "/"
  assume_role_policy    = data.aws_iam_policy_document.ecs-service-policy.json
  force_detach_policies = true
}
resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
  role       = aws_iam_role.ecs-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role       = aws_iam_role.ecs-service-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

#  key pair
resource "aws_key_pair" "ec2_key" {
  key_name   = var.key_pair_name
  public_key = var.key_pair_public_key
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-cluster"
}

resource "aws_launch_template" "ecs_launch_template" {
  image_id               = data.aws_ami.amazon-linux-2.id
  name_prefix            = "${var.project_name}-launch-config"
  vpc_security_group_ids = var.network_security_groups


  instance_type = var.ec2_instance_type
  key_name      = aws_key_pair.ec2_key.key_name

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", { ECS_CLUSTER = aws_ecs_cluster.ecs_cluster.name, TG_ARN = aws_lb_target_group.ecs_tg.arn }))

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs-instance-profile.arn
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


resource "aws_autoscaling_group" "ecs_asg" {
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.network_subnets

  desired_capacity = var.ecs_asg_desired_capacity
  min_size         = var.ecs_asg_min_size
  max_size         = var.ecs_asg_max_size

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

resource "aws_ecs_capacity_provider" "ecs_asg_cap_provider" {
  name = "${var.project_name}-asg-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn
    # decides whether to terminate aka delete the instances when they scale in
    #managed_termination_protection = "ENABLED"

    # TODO: enable these and allow variables 
    #managed_scaling {
    #maximum_scaling_step_size = 1000
    #minimum_scaling_step_size = 1
    #status                    = "ENABLED"
    #target_capacity           = 10
    #}
  }

}

# assign the capacity provider to the cluster
resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_cap_provider" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_asg_cap_provider.name]

  #default_capacity_provider_strategy {
  #base              = 1
  #weight            = 100
  #capacity_provider = ""
  #}
}

resource "aws_ecs_task_definition" "ecs_task_def" {
  family                = "${var.project_name}-task-def"
  container_definitions = <<TASK_DEFINITION
  [
      {
        "memoryReservation": 256,
        "environment": [
            {"name": "MONGO_USERNAME", "value":"${var.MONGO_USERNAME}"},
            {"name": "MONGO_PASSWORD", "value":"${var.MONGO_PASSWORD}"},
            {"name": "MONGO_HOST", "value":"${var.MONGO_HOST}"},
            {"name": "SERVER_PORT", "value":"8080"},
            {"name": "JWT_SECRET", "value":"SOMEJWTSECRET"},
            {"name": "KAFKA_BOOTSTRAP_SERVER","value":"kafka:9092" }
        ],
        "essential": true,
        "image": "docker.io/loyaltyapplication/go-gin-backend:latest",
        "name": "${var.project_name}-container",
        "portMappings": [
          {
            "containerPort": 8080,
            "hostPort": 0
          }
        ]
      }
    ]
    TASK_DEFINITION

}

resource "aws_ecs_service" "ecs_service" {
  name                 = "${aws_ecs_cluster.ecs_cluster.name}-service"
  cluster              = aws_ecs_cluster.ecs_cluster.id
  task_definition      = aws_ecs_task_definition.ecs_task_def.arn
  iam_role             = aws_iam_role.ecs-service-role.arn
  desired_count        = 1
  force_new_deployment = true

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "${var.project_name}-container"
    container_port   = 8080
  }

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_asg_cap_provider.name
  }

  # prevent race condition
  depends_on = [
    aws_iam_role.ecs-service-role
  ]

}

# load balancer 
resource "aws_lb_target_group" "ecs_tg" {
  name                 = "${var.project_name}-target-group"
  vpc_id               = var.network_vpc_id
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 5

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher             = 200
    protocol            = "HTTP"
    path                = var.health_check_path
  }

}

resource "aws_lb" "ecs_alb" {
  name               = "${var.project_name}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.network_security_groups
  subnets            = var.network_subnets
}

resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  // create cert
  certificate_arn = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }

}

# attach asg to lb
resource "aws_autoscaling_attachment" "tg_lb_attachement" {
  autoscaling_group_name = aws_autoscaling_group.ecs_asg.id
  lb_target_group_arn    = aws_lb_target_group.ecs_tg.arn
}
