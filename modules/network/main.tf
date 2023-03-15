resource "aws_vpc" "network_vpc" {
  cidr_block = var.network_vpc_cidr

}
resource "aws_subnet" "network_subnet_private" {
  for_each          = zipmap(var.network_subnet_private_cidrs, var.network_subnet_availability_zones)
  cidr_block        = each.key
  availability_zone = each.value
  vpc_id            = aws_vpc.network_vpc.id
}

