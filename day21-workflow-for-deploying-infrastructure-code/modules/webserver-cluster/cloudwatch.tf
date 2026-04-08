# ==============================================================================
# Day 21 — Feature Branch Change: CloudWatch Alarms for Webserver Cluster
# Branch: add-cloudwatch-alarms-day21
# Author: Infrastructure Team
# ==============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# Local Values — Common tags applied to all resources
# ─────────────────────────────────────────────────────────────────────────────
locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Module      = "webserver-cluster"
    Environment = var.cluster_name
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# CPU Utilisation Alarm — triggers scale-out SNS notification
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.cluster_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120 # seconds — 2-minute evaluation window
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "CPU > ${var.cpu_high_threshold}% for two consecutive 2-minute periods on ${var.cluster_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webserver.name
  }

  alarm_actions             = [aws_sns_topic.alerts.arn]
  ok_actions                = [aws_sns_topic.alerts.arn]
  insufficient_data_actions = []

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# CPU Low Alarm — triggers scale-in to avoid over-provisioning
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.cluster_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "CPU < ${var.cpu_low_threshold}% for three consecutive 2-minute periods on ${var.cluster_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.webserver.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# ALB 5xx Error Rate Alarm — catches application-level errors before users do
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.cluster_name}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "ALB is returning >=${var.alb_5xx_threshold} 5xx responses/min on ${var.cluster_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.webserver.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# ALB Unhealthy Host Count — catches instances that have failed health checks
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.cluster_name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "One or more targets in ${var.cluster_name} are unhealthy"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.webserver.arn_suffix
    TargetGroup  = aws_lb_target_group.webserver.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# SNS Topic — single fan-out point for all alarm notifications
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name              = "${var.cluster_name}-alerts"
  kms_master_key_id = "alias/aws/sns" # encrypt at rest with AWS-managed key

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ─────────────────────────────────────────────────────────────────────────────
# CloudWatch Dashboard — single-pane view of cluster health
# ─────────────────────────────────────────────────────────────────────────────
resource "aws_cloudwatch_dashboard" "webserver_cluster" {
  dashboard_name = "${var.cluster_name}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CPU Utilisation"
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName",
            aws_autoscaling_group.webserver.name]
          ]
          annotations = {
            horizontal = [
              { label = "High threshold", value = var.cpu_high_threshold, color = "#ff6961" },
              { label = "Low threshold", value = var.cpu_low_threshold, color = "#ffb347" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count & 5xx Errors"
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.webserver.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.webserver.arn_suffix]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 6
        width  = 24
        height = 4
        properties = {
          title = "Cluster Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.cpu_high.arn,
            aws_cloudwatch_metric_alarm.cpu_low.arn,
            aws_cloudwatch_metric_alarm.alb_5xx_errors.arn,
            aws_cloudwatch_metric_alarm.unhealthy_hosts.arn,
          ]
        }
      }
    ]
  })
}
