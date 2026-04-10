# modules/networking/vpc/main.tf
# Reusable VPC module — public + private subnets, NAT gateway, route tables

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "${var.name}-vpc"
    ManagedBy = "terraform"
    Env       = var.environment
  }
}

# -------------------------
# Internet Gateway
# -------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "${var.name}-igw"
    ManagedBy = "terraform"
    Env       = var.environment
  }
}

# -------------------------
# Public subnets
# -------------------------
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.name}-public-${count.index + 1}"
    ManagedBy = "terraform"
    Env       = var.environment
    Tier      = "public"
  }
}

# -------------------------
# Private subnets
# -------------------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name      = "${var.name}-private-${count.index + 1}"
    ManagedBy = "terraform"
    Env       = var.environment
    Tier      = "private"
  }
}

# -------------------------
# Elastic IP for NAT Gateway
# -------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name      = "${var.name}-nat-eip"
    ManagedBy = "terraform"
    Env       = var.environment
  }
}

# -------------------------
# NAT Gateway (in first public subnet)
# -------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name      = "${var.name}-nat"
    ManagedBy = "terraform"
    Env       = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

# -------------------------
# Public route table
# -------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name      = "${var.name}-public-rt"
    ManagedBy = "terraform"
    Env       = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Private route table (via NAT)
# -------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name      = "${var.name}-private-rt"
    ManagedBy = "terraform"
    Env       = var.environment
  }
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
