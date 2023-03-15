resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon-linux-2.id
  subnet_id              = var.ec2_subnet_id
  instance_type          = var.ec2_instance_type
  iam_instance_profile   = var.ec2_iam_instance_profile
  vpc_security_group_ids = var.ec2_vpc_security_group_ids
  key_name               = var.ec2_key_pair_name
  user_data              = templatefile("${path.module}/user_data.tftpl", { ECS_CLUSTER = var.ecs_cluster_name })

  lifecycle {
    ignore_changes = [ami, user_data, subnet_id, key_name, ebs_optimized, private_ip]
  }
}


resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

#resource "aws_autoscaling_group" "ecs_asg" {
#name                 = ""
#vpc_zone_identifier  = [var.ec2_subnet_id]
#launch_configuration = aws_launch_configuration.ecs_launch_config.name

#desired_capacity          = 2
#min_size                  = 1
#max_size                  = 10
#health_check_grace_period = 300
#health_check_type         = "EC2"
#}
