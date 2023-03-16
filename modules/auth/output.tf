output "key_pair_name" {
  value = aws_key_pair.auth.key_name
}

output "iam_ecs_instance_role" {
  value = aws_iam_role.ecs-instance-role.name
}

output "iam_ecs_service_role" {
  value = aws_iam_role.ecs-service-role.name
}

output "iam_ecs_instance_profile" {
  value = aws_iam_instance_profile.ecs-instance-profile.name
}
