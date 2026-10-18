resource "aws_vpc" "twk" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "twk-vpc" })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_internet_gateway" "twk" {
  vpc_id = aws_vpc.twk.id
  tags   = merge(var.tags, { Name = "${var.env_prefix}-igw" })
}

resource "aws_subnet" "dev" {
  vpc_id                  = aws_vpc.twk.id # a reference = a dependency
  cidr_block              = var.dev_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.env_prefix}-subnet-dev" })
}

resource "aws_route_table" "dev" {
  vpc_id = aws_vpc.twk.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.twk.id
  }

  tags = merge(var.tags, { Name = "${var.env_prefix}-rt-dev" })
}

resource "aws_route_table_association" "dev" {
  subnet_id      = aws_subnet.dev.id
  route_table_id = aws_route_table.dev.id
}

resource "aws_security_group" "dev" {
  name        = "${var.env_prefix}-sg-dev"
  description = "twk dev server: SSH from owner IP only, 80/443 public"
  vpc_id      = aws_vpc.twk.id
  tags        = merge(var.tags, { Name = "${var.env_prefix}-sg-dev" })
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.dev.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_cidr
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.dev.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.dev.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.dev.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
