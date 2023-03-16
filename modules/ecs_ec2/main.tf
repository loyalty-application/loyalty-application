resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = data.aws_ami.amazon-linux-2.id
  iam_instance_profile = var.ec2_iam_instance_profile
  security_groups      = var.ec2_vpc_security_group_ids
  instance_type        = var.ec2_instance_type
  key_name             = var.ec2_key_pair_name
  root_block_device {
    volume_type = var.ec2_volume_type
    volume_size = var.ec2_volume_size
  }
  user_data = templatefile("${path.module}/user_data.tftpl", { ECS_CLUSTER = var.ecs_cluster_name })
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                 = var.ecs_asg_name
  vpc_zone_identifier  = var.ecs_asg_subnets
  launch_configuration = aws_launch_configuration.ecs_launch_config.name

  desired_capacity          = var.ecs_asg_desired_capacity
  min_size                  = var.ecs_asg_min_size
  max_size                  = var.ecs_asg_max_size
  health_check_grace_period = var.ecs_asg_hc_grace_period
  health_check_type         = var.ecs_asg_hc_type
}
