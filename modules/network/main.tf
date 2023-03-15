variable "network_subnet_private_cidrs" {
  type        = list(string)
  description = "List of cidr blocks, with each element repesenting a private subnet"
  default     = cidrsubnets(aws_vpc.main_vpc.cidr_block, 4, 4, 4)
}
variable "network_subnet_availability_zones" {
  type        = list(string)
  description = "List of availability zones, with each element representing an aws availability zone"
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}

variable "network_vpc_cidr" {
  type        = string
  description = "network address of VPC"
  default     = "10.0.0.0/20"
}

resource "aws_vpc" "network_vpc" {
  cidr_block = var.network_vpc_cidr
}
resource "aws_subnet" "network_subnet_private" {
  for_each          = zipmap(var.network_subnet_private_cidrs, var.network_subnet_availability_zones)
  cidr_block        = each.key
  availability_zone = each.value
  vpc_id            = aws_vpc.network_vpc.id
}

