# =============================================================================
# MODULE: monitoring
# Description: CloudWatch alarms, SNS topics, log groups, dashboard
# =============================================================================

locals {
  common_tags = merge(var.common_tags, {
    Module = "monitoring"
  })
}

data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# SNS Topic for Alerts
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name              = "${var.cluster_name}-alerts"
  kms_master_key_id = var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-alerts"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = length(var.alert_email_addresses)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# ---------------------------------------------------------------------------
# CloudWatch Log Groups
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "application" {
  name              = "/app/${var.cluster_name}/application"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-app-logs"
  })
}

resource "aws_cloudwatch_log_group" "access" {
  name              = "/app/${var.cluster_name}/access"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-access-logs"
  })
}

resource "aws_cloudwatch_log_group" "system" {
  name              = "/app/${var.cluster_name}/system"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-system-logs"
  })
}

# ---------------------------------------------------------------------------
# CPU Utilization Alarms
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.cluster_name}-high-cpu"
  alarm_description   = "Triggers when average CPU exceeds ${var.cpu_high_threshold}% for 4 minutes. Initiates scale-out."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn,
    var.scale_out_policy_arn
  ]
  ok_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.cluster_name}-low-cpu"
  alarm_description   = "Triggers when average CPU is below ${var.cpu_low_threshold}% for 10 minutes. Initiates scale-in."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [var.scale_in_policy_arn]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# ALB 5xx Error Rate Alarm
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.cluster_name}-alb-5xx-errors"
  alarm_description   = "Triggers when ALB 5xx error rate exceeds ${var.error_rate_threshold}% over 5 minutes."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = var.error_rate_threshold
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "error_rate"
    expression  = "errors / requests * 100"
    label       = "5xx Error Rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5XX_Count"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  metric_query {
    id = "requests"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# ALB Target Response Time Alarm
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${var.cluster_name}-alb-latency"
  alarm_description   = "Triggers when p95 response time exceeds ${var.latency_threshold_seconds}s."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p95"
  threshold           = var.latency_threshold_seconds
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Unhealthy Hosts Alarm
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.cluster_name}-unhealthy-hosts"
  alarm_description   = "Triggers immediately when any target group host becomes unhealthy."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# CloudWatch Dashboard
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
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
          title  = "CPU Utilization"
          region = data.aws_region.current.name
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]
          ]
          annotations = {
            horizontal = [
              { value = var.cpu_high_threshold, label = "Scale-out threshold", color = "#ff6961" },
              { value = var.cpu_low_threshold, label = "Scale-in threshold", color = "#77dd77" }
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
          title  = "Request Count & 5xx Errors"
          region = data.aws_region.current.name
          period = 60
          annotations = {}
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "Requests" }],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", label = "5xx Errors", color = "#ff6961" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Target Response Time (p50, p95, p99)"
          region = data.aws_region.current.name
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p50", label = "p50" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p95", label = "p95" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p99", label = "p99", color = "#ff6961" }]
          ]
          annotations = {
            horizontal = [{ value = var.latency_threshold_seconds, label = "SLA threshold", color = "#ff6961" }]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ASG Instance Count"
          region = data.aws_region.current.name
          period = 60
          annotations = {}
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "In Service" }],
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "Desired" }]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 12
        width  = 24
        height = 4
        properties = {
          title = "Active Alarms"
          alarms = [
            aws_cloudwatch_metric_alarm.high_cpu.arn,
            aws_cloudwatch_metric_alarm.alb_5xx_errors.arn,
            aws_cloudwatch_metric_alarm.alb_latency.arn,
            aws_cloudwatch_metric_alarm.unhealthy_hosts.arn
          ]
        }
      }
    ]
  })
}
