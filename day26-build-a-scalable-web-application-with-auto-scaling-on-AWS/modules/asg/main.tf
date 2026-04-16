# Data source to get current AWS region dynamically
data "aws_region" "current" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "scalable-web-app"
  })
}

resource "aws_autoscaling_group" "web" {
  name                = "web-asg-${var.environment}"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Allow immediate destruction in non-production environments
  force_delete = var.environment != "production"

  dynamic "tag" {
    for_each = merge(local.common_tags, { Name = "web-${var.environment}" })
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

# ─── Scale-out policy: add one instance when CPU is high ────────────────────
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "web-scale-out-${var.environment}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# ─── Scale-in policy: remove one instance when CPU drops ────────────────────
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "web-scale-in-${var.environment}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

# ─── CloudWatch alarm: CPU too high → scale out ─────────────────────────────
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "web-cpu-high-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_scale_out_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Scale out when average CPU >= ${var.cpu_scale_out_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_out.arn]
}

# ─── CloudWatch alarm: CPU too low → scale in ───────────────────────────────
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "web-cpu-low-${var.environment}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_scale_in_threshold

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_description = "Scale in when average CPU <= ${var.cpu_scale_in_threshold}%"
  alarm_actions     = [aws_autoscaling_policy.scale_in.arn]
}

# ─── Bonus: CloudWatch Dashboard ────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "web" {
  dashboard_name = "web-asg-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width = 12
        height = 6
        properties = {
          title  = "CPU Utilization"
          region = data.aws_region.current.id
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web.name]
          ]
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 0
        width = 12
        height = 6
        properties = {
          title  = "ASG Instance Count"
          region = data.aws_region.current.id
          period = 300
          stat   = "Average"
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.web.name]
          ]
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      }
    ]
  })
}
