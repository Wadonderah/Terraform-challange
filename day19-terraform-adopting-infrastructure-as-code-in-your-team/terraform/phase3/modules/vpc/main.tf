################################################################################
# Phase 3 — Shared VPC module
#
# Once multiple engineers are writing Terraform, you need shared modules.
# Otherwise you end up with five different ways to create a VPC, none of them
# consistent, and a debugging nightmare every time something breaks.
#
# This module is opinionated. It makes choices so you don't have to repeat them:
# - 3 AZs, always (us losing one AZ should be boring, not a crisis)
# - Public subnets for load balancers, private for everything else
# - NAT gateways per AZ (yes it costs more, cross-AZ NAT traffic during
#   an AZ failure has bitten us before)
# - Flow logs on by default — you will want them when things go wrong
################################################################################

variable "project_name" {
  description = "Prefix for all resource names — keep it short"
  type        = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. /16 gives you room to grow."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to deploy into — defaults to 3"
  type        = list(string)
}

variable "enable_flow_logs" {
  description = "Ship VPC flow logs to CloudWatch. Default true. Turn off only in dev to save money."
  type        = bool
  default     = true
}

###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Carve up the CIDR cleanly — public /24s, private /20s
  # Public subnets are small: only load balancers live there
  # Private subnets are large: everything else does
  public_cidrs  = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i)]
  private_cidrs = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, i + 4)]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${var.availability_zones[count.index]}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-private-${var.availability_zones[count.index]}"
    Tier = "private"
  }
}

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "this" {
  count = length(var.availability_zones)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${local.name_prefix}-nat-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

###############################################################################
# VPC Flow Logs
# You don't think you need these until you're debugging a network issue at 2am.
###############################################################################

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flow-logs/${local.name_prefix}"
  retention_in_days = 30
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn
}

###############################################################################
# Outputs — everything a downstream module might need
###############################################################################

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
