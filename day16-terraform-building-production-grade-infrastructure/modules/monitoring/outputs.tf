output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts."
  value       = aws_sns_topic.alerts.arn
}

output "application_log_group_name" {
  description = "Name of the application CloudWatch log group."
  value       = aws_cloudwatch_log_group.application.name
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard."
  value       = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "high_cpu_alarm_arn" {
  description = "ARN of the high CPU CloudWatch alarm."
  value       = aws_cloudwatch_metric_alarm.high_cpu.arn
}
