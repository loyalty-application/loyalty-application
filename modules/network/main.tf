# main vpc
resource "aws_vpc" "network_vpc" {

  cidr_block           = var.network_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# private subnet
resource "aws_subnet" "network_subnet_private" {
  for_each          = zipmap(var.network_subnet_private_cidrs, var.network_subnet_availability_zones)
  cidr_block        = each.key
  availability_zone = each.value
  vpc_id            = aws_vpc.network_vpc.id
}
# public subnet
resource "aws_subnet" "network_subnet_public" {
  for_each                = zipmap(var.network_subnet_public_cidrs, var.network_subnet_availability_zones)
  cidr_block              = each.key
  availability_zone       = each.value
  vpc_id                  = aws_vpc.network_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.network_vpc.id
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
  depends_on = [
    aws_subnet.network_subnet_public
  ]
  for_each       = { for i, val in aws_subnet.network_subnet_public : i => val.id }
  subnet_id      = each.value
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "ecs_ec2_security_group" {
  name        = "ecs_ec2_security_group"
  description = "ecs_ec2_security_group"
  vpc_id      = aws_vpc.network_vpc.id

  ingress {
    description = "Allow ssh from internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_security_group_rule" "example" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_ec2_security_group.id
}
