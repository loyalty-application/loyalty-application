output "cp" {
  value = aws_ecs_capacity_provider.this
}

output "cluster" {
  value = aws_ecs_cluster.this
}

output "asg" {
  value = aws_autoscaling_group.this
}
