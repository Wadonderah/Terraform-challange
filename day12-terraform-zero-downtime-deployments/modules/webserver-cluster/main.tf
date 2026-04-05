###############################################################################
# modules/webserver-cluster/main.tf
# Day 12 — Zero-Downtime Deployments with Terraform
#
# Key patterns:
#   1. create_before_destroy on Launch Template + ASG
#   2. name_prefix (not name) on ASG — avoids duplicate-name conflict
#   3. random_id keyed on ami — new ID when image changes
#   4. Blue/Green target groups with listener rule switch
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Data Sources
# ─────────────────────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"
}

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

locals {
  ami_id = var.ami != "" ? var.ami : data.aws_ami.ubuntu.id

  # Version-to-colour mapping for visual distinction in the browser

  version_color = {
    "v1" = "#1A56DB" # blue
    "v2" = "#16A34A" # green
    "v3" = "#D97706" # amber
  }

  blue_color  = lookup(local.version_color, var.blue_app_version, "#1A56DB")
  green_color = lookup(local.version_color, var.green_app_version, "#16A34A")

  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Cluster     = var.cluster_name
    Day         = "12"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# PATTERN: random_id keyed on AMI
#
# A new random_id is generated whenever the AMI changes. This feeds into the
# Launch Template name, which forces a new Launch Template to be created,
# which then triggers a new ASG via create_before_destroy.
# ─────────────────────────────────────────────────────────────────────────────

resource "random_id" "blue" {
  keepers = {
    ami_id      = local.ami_id
    app_version = var.blue_app_version
  }
  byte_length = 4
}

resource "random_id" "green" {
  keepers = {
    ami_id      = local.ami_id
    app_version = var.green_app_version
  }
  byte_length = 4
}

# ─────────────────────────────────────────────────────────────────────────────
# Networking
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.common_tags, { Name = "${var.cluster_name}-vpc" })
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(local.common_tags, { Name = "${var.cluster_name}-public-${count.index + 1}" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${var.cluster_name}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(local.common_tags, { Name = "${var.cluster_name}-rt" })
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
  vpc_id      = aws_vpc.main.id

  ingress {
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
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "web" {
  name_prefix = "${var.cluster_name}-web-"
  description = "Allow HTTP from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
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
  lifecycle { create_before_destroy = true }
}

# ─────────────────────────────────────────────────────────────────────────────
# ALB
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  tags               = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# BLUE Target Group + Launch Template + ASG
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "blue" {
  name     = "${var.cluster_name}-blue-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
  }
  tags = merge(local.common_tags, { Color = "blue" })
}

resource "aws_launch_template" "blue" {
  # name includes random_id so a new LT is created when app_version changes
  name                   = "${var.cluster_name}-blue-${random_id.blue.hex}"
  image_id               = local.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    app_version  = var.blue_app_version
    cluster_name = var.cluster_name
    environment  = var.environment
    color        = local.blue_color
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${var.cluster_name}-blue", Color = "blue" })
  }

  # PATTERN: create_before_destroy
  # New Launch Template exists before the old one is removed.
  # This ensures the ASG can reference the new LT immediately.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "blue" {
  # PATTERN: name_prefix instead of name
  # AWS does not allow two ASGs with the same name to coexist.
  # name_prefix lets AWS generate a unique name on each create,
  # which is required when create_before_destroy = true.
  name_prefix         = "${var.cluster_name}-blue-"
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.blue.arn]
  health_check_type   = "ELB"

  # Wait for instances to pass health checks before Terraform marks the
  # resource as complete. This is what prevents the old ASG from being
  # destroyed before the new one is actually serving traffic.
  wait_for_capacity_timeout = "10m"

  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }

  # PATTERN: create_before_destroy on the ASG
  # New ASG (with new LT) is fully healthy before old ASG is destroyed.

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-blue"
    propagate_at_launch = true
  }
  tag {
    key                 = "Color"
    value               = "blue"
    propagate_at_launch = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# GREEN Target Group + Launch Template + ASG
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "green" {
  name     = "${var.cluster_name}-green-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
  }
  tags = merge(local.common_tags, { Color = "green" })
}

resource "aws_launch_template" "green" {
  name                   = "${var.cluster_name}-green-${random_id.green.hex}"
  image_id               = local.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    app_version  = var.green_app_version
    cluster_name = var.cluster_name
    environment  = var.environment
    color        = local.green_color
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${var.cluster_name}-green", Color = "green" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "green" {
  name_prefix         = "${var.cluster_name}-green-"
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.green.arn]
  health_check_type   = "ELB"

  wait_for_capacity_timeout = "10m"

  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-green"
    propagate_at_launch = true
  }
  tag {
    key                 = "Color"
    value               = "green"
    propagate_at_launch = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# ALB Listener + Blue/Green Routing Rule
#
# PATTERN: The listener rule points to ONE target group at a time.
# Changing active_environment flips the target group in a single API call —
# this is what makes the traffic switch instantaneous with no downtime window.
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default action — send all traffic to the active target group
  default_action {
    type             = "forward"
    target_group_arn = var.active_environment == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }
}
