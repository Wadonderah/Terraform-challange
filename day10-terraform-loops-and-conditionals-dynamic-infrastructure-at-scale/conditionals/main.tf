# =============================================================
# Day 10 — Conditional Logic
# =============================================================
# Terraform conditionals use the ternary operator:
#   condition ? value_if_true : value_if_false
#
# Most powerful pattern: combine with count to make resources
# optional without removing them from your config.
# =============================================================

# ── Variables ─────────────────────────────────────────────────
variable "enable_autoscaling" {
  description = "Set to true to create autoscaling policies for the cluster"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Deployment environment: dev, staging, or production"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be one of: dev, staging, production."
  }
}

variable "cluster_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
  default     = "webserver-cluster"
}

# ── Local: centralise conditional logic ──────────────────────
# Keep ternaries in ONE place rather than scattered across resources.
locals {
  instance_type       = var.environment == "production" ? "t3.medium" : "t3.micro"
  min_size            = var.environment == "production" ? 3 : 1
  max_size            = var.environment == "production" ? 10 : 3
  desired             = var.environment == "production" ? 3 : 1
  deletion_protection = var.environment == "production" ? true : false

  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "30DayTerraformChallenge"
  }
}

# ── Launch Template ───────────────────────────────────────────
resource "aws_launch_template" "web" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type # ← conditional via local

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
    echo "<h1>Hello from ${var.environment}</h1>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = local.common_tags
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Auto Scaling Group ────────────────────────────────────────
resource "aws_autoscaling_group" "web" {
  name                = var.cluster_name
  min_size            = local.min_size
  max_size            = local.max_size
  desired_capacity    = local.desired
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

# ── Autoscaling Policies (OPTIONAL via count) ─────────────────
# count = 0  → resource is NOT created (skipped entirely)
# count = 1  → resource IS created
# This is the canonical Terraform pattern for optional resources.

resource "aws_autoscaling_policy" "scale_out" {
  count = var.enable_autoscaling ? 1 : 0 # ← THE KEY PATTERN

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
  alarm_description   = "Scale out when average CPU > 80% for 4 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out[0].arn]
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
  alarm_description   = "Scale in when average CPU < 30% for 4 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in[0].arn]
}

# ── Data Sources ──────────────────────────────────────────────
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

# ── Outputs ───────────────────────────────────────────────────
output "instance_type" {
  description = "Instance type chosen for this environment"
  value       = local.instance_type
}

output "autoscaling_enabled" {
  description = "Whether autoscaling policies were created"
  value       = var.enable_autoscaling
}

output "scale_out_policy_arn" {
  description = "Scale-out policy ARN (empty string if autoscaling disabled)"
  value       = var.enable_autoscaling ? aws_autoscaling_policy.scale_out[0].arn : "N/A — autoscaling disabled"
}

output "cluster_config_summary" {
  description = "Summary of cluster configuration for this environment"
  value = {
    environment    = var.environment
    instance_type  = local.instance_type
    min_size       = local.min_size
    max_size       = local.max_size
    autoscaling_on = var.enable_autoscaling
  }
}
