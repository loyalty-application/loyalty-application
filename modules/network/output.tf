output "network_subnets_private" {
  value = [for x in aws_subnet.network_subnet_private : x.id]
}
output "network_subnets_public" {
  value = [aws_subnet.network_subnet_public.id]
}
output "network_vpc_id" {
  value = aws_vpc.network_vpc.id
}
