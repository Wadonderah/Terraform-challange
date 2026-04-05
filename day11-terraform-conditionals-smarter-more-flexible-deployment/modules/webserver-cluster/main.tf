###############################################################################
# modules/webserver-cluster/main.tf
# Day 11 — Terraform Conditionals Deep Dive
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# PATTERN 1 — Conditional Data Source Lookup (brownfield vs greenfield)
#
# count = 1 → look up the existing VPC
# count = 0 → skip the data source entirely (no API call made)
# ─────────────────────────────────────────────────────────────────────────────

data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0

  tags = {
    Name = var.existing_vpc_name_tag
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# PATTERN 1 cont. — Conditional Resource Creation (greenfield VPC)
#
# count = 0 when use_existing_vpc = true  → skip resource creation
# count = 1 when use_existing_vpc = false → create a brand-new VPC
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_vpc" "new" {
  count = var.use_existing_vpc ? 0 : 1

  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "${var.cluster_name}-vpc" })
}

# ─────────────────────────────────────────────────────────────────────────────
# Launch Template — uses locals.instance_type driven by environment
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_launch_template" "web" {
  name_prefix            = "${var.cluster_name}-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = local.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
  EOF
  )

  monitoring {
    enabled = local.enable_monitoring
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${var.cluster_name}-web" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Auto Scaling Group — min/max driven by environment, spans both AZs
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_autoscaling_group" "web" {
  name_prefix         = "${var.cluster_name}-"
  min_size            = local.min_size          # ← conditional value from locals
  max_size            = local.max_size          # ← conditional value from locals
  vpc_zone_identifier = aws_subnet.public[*].id # both subnets for HA
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# PATTERN 2 — Conditional Resource Creation: CloudWatch alarm
#
# count = 1  → alarm is created   (enable_monitoring = true)
# count = 0  → alarm is NOT created (enable_monitoring = false)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = local.enable_monitoring ? 1 : 0

  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilisation exceeded 80% for two consecutive 2-minute periods"

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# PATTERN 2 cont. — Conditional Resource Creation: Route53 record
#
# count = 1  → DNS alias record created   (create_dns_record = true)
# count = 0  → no DNS record              (create_dns_record = false)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_route53_record" "alb" {
  count = var.create_dns_record ? 1 : 0

  zone_id = data.aws_route53_zone.primary[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}

data "aws_route53_zone" "primary" {
  count        = var.create_dns_record ? 1 : 0
  name         = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
  private_zone = false
}

# ─────────────────────────────────────────────────────────────────────────────
# Availability Zones — look up what's available in the current region
# ─────────────────────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

# ─────────────────────────────────────────────────────────────────────────────
# Two public subnets in two different AZs
# AWS ALBs REQUIRE >= 2 subnets in >= 2 different Availability Zones.
# We use count = 2 and index into the AZ list so this works in any region.
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.${count.index + 1}.0/24" # 10.0.1.0/24 and 10.0.2.0/24
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-public-${count.index + 1}"
  })
}

# ─────────────────────────────────────────────────────────────────────────────
# Internet Gateway — required for public subnets to reach the internet
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = local.vpc_id

  tags = merge(local.common_tags, { Name = "${var.cluster_name}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, { Name = "${var.cluster_name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Groups
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.cluster_name}-alb-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "web" {
  name_prefix = "${var.cluster_name}-web-"
  description = "Allow HTTP inbound from ALB only"
  vpc_id      = local.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.cluster_name}-web-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Application Load Balancer — with 2 subnets across 2 AZs
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_lb" "web" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id # both subnets — satisfies the 2-AZ requirement

  tags = local.common_tags
}

resource "aws_lb_target_group" "web" {
  name     = "${var.cluster_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 30
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# AMI data source
# ─────────────────────────────────────────────────────────────────────────────

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
