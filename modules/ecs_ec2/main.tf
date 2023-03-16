resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-cluster"
}

resource "aws_launch_configuration" "ecs_launch_config" {
  name_prefix          = "${var.project_name}-launch-config"
  image_id             = data.aws_ami.amazon-linux-2.id
  iam_instance_profile = var.ec2_iam_instance_profile
  security_groups      = var.ec2_vpc_security_group_ids
  instance_type        = var.ec2_instance_type
  key_name             = var.ec2_key_pair_name
  root_block_device {
    volume_type = var.ec2_volume_type
    volume_size = var.ec2_volume_size
  }
  user_data = <<EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.ecs_cluster.name} >> /etc/ecs/ecs.config
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                 = "${var.project_name}-asg"
  vpc_zone_identifier  = var.ecs_asg_subnets
  launch_configuration = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = var.ecs_asg_desired_capacity
  min_size                  = var.ecs_asg_min_size
  max_size                  = var.ecs_asg_max_size
  health_check_grace_period = var.ecs_asg_hc_grace_period
  health_check_type         = var.ecs_asg_hc_type



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
  cluster_name = aws_ecs_cluster.ecs_cluster.name

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
        "cpu": 1024,
        "memory": 512,
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
  name            = "${aws_ecs_cluster.ecs_cluster.name}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_def.arn
  desired_count   = 1
}
