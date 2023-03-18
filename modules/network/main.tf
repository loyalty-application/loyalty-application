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
  depends_on = [
    aws_vpc.network_vpc,
  ]
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
    description = "allow all"
    from_port   = 0
    to_port     = 65535
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


# create a subdomain zone
resource "aws_route53_zone" "domain" {
  name = var.project_domain
}

resource "aws_route53_record" "record_subdomain_cname" {
  zone_id = aws_route53_zone.domain.zone_id
  name    = var.project_name
  type    = "CNAME"
  ttl     = 300
  records = [var.aws_lb_dns_name]
}

resource "aws_route53domains_registered_domain" "domain" {
  domain_name = var.project_domain
  name_server {
    name = aws_route53_zone.domain.name_servers[0]
  }
  name_server {
    name = aws_route53_zone.domain.name_servers[1]
  }
  name_server {
    name = aws_route53_zone.domain.name_servers[2]
  }
  name_server {
    name = aws_route53_zone.domain.name_servers[3]
  }
}

# dns validation for domain
resource "aws_acm_certificate" "cert_validation" {
  domain_name       = "${var.project_name}.${var.project_domain}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "cert_validation_records" {
  certificate_arn         = aws_acm_certificate.cert_validation.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_validation : record.fqdn]
}

resource "aws_route53_record" "dns_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert_validation.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.domain.zone_id
}
