output "network_subnets_private" {
  value = [for x in aws_subnet.network_subnet_private : x.id]
}
output "network_subnets_public" {
  value = [for x in aws_subnet.network_subnet_public : x.id]
}
output "network_vpc_id" {
  value = aws_vpc.network_vpc.id
}
output "network_security_group_id" {
  value = aws_security_group.ecs_ec2_security_group.id
}
