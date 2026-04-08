# ==============================================================================
# outputs.tf — Day 21 additions
# Exposes the ASG name (required by Day 21 task) and all alarm ARNs so
# consuming root modules can wire alarms into dashboards or other automation.
# ==============================================================================

output "asg_name" {
  description = "Name of the Auto Scaling Group. Use this to filter CloudWatch metrics."
  value       = aws_autoscaling_group.webserver.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group."
  value       = aws_autoscaling_group.webserver.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.webserver.dns_name
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB — used in CloudWatch metric dimensions."
  value       = aws_lb.webserver.arn_suffix
}

output "cloudwatch_dashboard_url" {
  description = "Direct URL to the CloudWatch dashboard for this cluster."
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.webserver_cluster.dashboard_name}"
}

output "alarm_arns" {
  description = "Map of alarm name → ARN for all alarms in this module."
  value = {
    cpu_high        = aws_cloudwatch_metric_alarm.cpu_high.arn
    cpu_low         = aws_cloudwatch_metric_alarm.cpu_low.arn
    alb_5xx_errors  = aws_cloudwatch_metric_alarm.alb_5xx_errors.arn
    unhealthy_hosts = aws_cloudwatch_metric_alarm.unhealthy_hosts.arn
  }
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic. Subscribe additional endpoints to this as needed."
  value       = aws_sns_topic.alerts.arn
}

# ─────────────────────────────────────────────────────────────────────────────
# Data source — current region, used in dashboard URL output above
# ─────────────────────────────────────────────────────────────────────────────
data "aws_region" "current" {}
