# =============================================================
# Day 10 — Refactored Webserver Cluster Module
# modules/webserver-cluster/main.tf
# =============================================================
# Changes from Days 3-9:
#   • Replaced repeated aws_iam_user blocks with for_each
#   • Made autoscaling policies optional via count
#   • Replaced hardcoded instance_type with conditional local
#   • Added for expressions in all outputs
#   • Centralised all conditional logic in locals{}
# =============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── Variables ───

variable "cluster_name" {
  description = "Name prefix for all resources in this cluster"
  type        = string
}

variable "environment" {
  description = "Environment name: dev, staging, or production"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Must be dev, staging, or production."
  }
}

variable "enable_autoscaling" {
  description = "Create CloudWatch alarms and scaling policies"
  type        = bool
  default     = true
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (defaults to latest Amazon Linux 2)"
  type        = string
  default     = null
}

# REPLACED: individual IAM user resource blocks
# BEFORE (Days 3-9 — fragile and repetitive):
#   resource "aws_iam_user" "alice" { name = "alice" }
#   resource "aws_iam_user" "bob"   { name = "bob"   }
#   resource "aws_iam_user" "carol" { name = "carol" }
#
# AFTER: single for_each block ↓

variable "iam_users" {
  description = "Map of IAM users to create with their configuration"
  type = map(object({
    department = string
    admin      = bool
  }))
  default = {}
}

variable "security_group_rules" {
  description = "Ingress rules to add to the webserver security group"
  type = map(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {
    http = {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTP from anywhere"
    }
    https = {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS from anywhere"
    }
  }
}

# ── Locals: ALL conditional logic lives here ───

locals {
  instance_type  = var.environment == "production" ? "t3.medium" : "t3.micro"
  min_size       = var.environment == "production" ? 3 : 1
  max_size       = var.environment == "production" ? 10 : 3
  desired        = var.environment == "production" ? 3 : 1
  ami            = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux.id

  common_tags = {
    Environment = var.environment
    Cluster     = var.cluster_name
    ManagedBy   = "Terraform"
    Day         = "10"
  }

  # Separate admin users for policy attachment — using for expression

  admin_users = {
    for name, cfg in var.iam_users : name => cfg
    if cfg.admin
  }
}

# ── Data Sources ───

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── Security Group (with dynamic rules via for_each) ───

resource "aws_security_group" "web" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for ${var.cluster_name} webserver cluster"
  vpc_id      = data.aws_vpc.default.id
  tags        = local.common_tags
}

# REPLACED: individual aws_security_group_rule blocks
# BEFORE: one block per port, all duplicated
# AFTER: single for_each block over the rules variable
resource "aws_security_group_rule" "ingress" {
  for_each = var.security_group_rules

  type              = "ingress"
  security_group_id = aws_security_group.web.id
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  security_group_id = aws_security_group.web.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# ── IAM Users (for_each replaces repeated resource blocks) ────
resource "aws_iam_user" "users" {
  for_each = var.iam_users
  name     = each.key

  tags = merge(local.common_tags, {
    Department = each.value.department
    IsAdmin    = tostring(each.value.admin)
  })
}

resource "aws_iam_user_policy_attachment" "admin" {
  for_each = local.admin_users

  user       = aws_iam_user.users[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ── Launch Template ───

resource "aws_launch_template" "web" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = local.ami
  instance_type = local.instance_type   # ← conditional via local

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = var.cluster_name
    environment  = var.environment
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Auto Scaling Group ───

resource "aws_autoscaling_group" "web" {
  name             = var.cluster_name
  min_size         = local.min_size
  max_size         = local.max_size
  desired_capacity = local.desired

  vpc_zone_identifier = data.aws_subnets.default.ids

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

  lifecycle {
    create_before_destroy = true
  }
}

# ── Autoscaling Policies (OPTIONAL — controlled by count) ─────

resource "aws_autoscaling_policy" "scale_out" {
  count = var.enable_autoscaling ? 1 : 0   # 0 = resource skipped entirely

  name                   = "${var.cluster_name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_in" {
  count = var.enable_autoscaling ? 1 : 0

  name                   = "${var.cluster_name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.web.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_autoscaling ? 1 : 0

  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out[0].arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  count = var.enable_autoscaling ? 1 : 0

  alarm_name          = "${var.cluster_name}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in[0].arn]
  tags          = local.common_tags
}

# ── Outputs (using for expressions) ───

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "security_group_id" {
  description = "ID of the webserver security group"
  value       = aws_security_group.web.id
}

output "instance_type" {
  description = "Instance type selected based on environment"
  value       = local.instance_type
}

output "user_arns" {
  description = "Map of username → ARN for all IAM users created by this module"
  # for expression: transforms for_each resource into a clean map
  value = { for name, user in aws_iam_user.users : name => user.arn }
}

output "admin_user_arns" {
  description = "ARNs for admin users only"
  value = {
    for name, user in aws_iam_user.users : name => user.arn
    if var.iam_users[name].admin
  }
}

output "cluster_summary" {
  description = "Human-readable cluster configuration summary"
  value = {
    name              = var.cluster_name
    environment       = var.environment
    instance_type     = local.instance_type
    min_size          = local.min_size
    max_size          = local.max_size
    autoscaling_on    = var.enable_autoscaling
    security_rules    = [for rule_name, rule in var.security_group_rules : "${rule_name}:${rule.port}"]
    iam_user_count    = length(var.iam_users)
    admin_user_count  = length(local.admin_users)
  }
}
