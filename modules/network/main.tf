resource "aws_vpc" "network_vpc" {
  cidr_block = var.network_vpc_cidr

}
# private subnet
resource "aws_subnet" "network_subnet_private" {
  for_each          = zipmap(var.network_subnet_private_cidrs, var.network_subnet_availability_zones)
  cidr_block        = each.key
  availability_zone = each.value
  vpc_id            = aws_vpc.network_vpc.id
}

# public subnet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.network_vpc.id
}
resource "aws_subnet" "network_subnet_public" {
  vpc_id     = aws_vpc.network_vpc.id
  cidr_block = var.network_subnet_public_cidr
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.network_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}
# associate route table with public subnet
resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.network_subnet_public.id
  route_table_id = aws_route_table.public_route_table.id
}
