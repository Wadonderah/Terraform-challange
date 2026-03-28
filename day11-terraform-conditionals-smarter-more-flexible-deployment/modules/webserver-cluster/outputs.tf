###############################################################################
# modules/webserver-cluster/outputs.tf
#
# PATTERN 3 — Safe output references for conditionally created resources
#
# When count = 0 the resource list is empty ([]).  Referencing [0].arn on an
# empty list causes:
#   Error: Invalid index — The given key does not identify an element in
#   this collection value.
#
# Fix: wrap every such reference in a ternary that returns null when the
# resource doesn't exist.  Callers then know to check for null before using.
###############################################################################

# ─────────────────────────────────────────────────────────────────────────────
# ALB — always created, safe to reference directly
# ─────────────────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.web.arn
}

# ─────────────────────────────────────────────────────────────────────────────
# CloudWatch alarm — CONDITIONALLY created
#
# Without guard:  aws_cloudwatch_metric_alarm.high_cpu[0].arn
#   → Runtime error when enable_monitoring = false (empty list)
#
# With guard:     enable_monitoring ? alarm[0].arn : null
#   → Returns null safely; callers handle null in their own logic
# ─────────────────────────────────────────────────────────────────────────────

output "alarm_arn" {
  description = "ARN of the CPU CloudWatch alarm, or null when monitoring is disabled"
  value       = local.enable_monitoring ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
}

output "alarm_name" {
  description = "Name of the CPU CloudWatch alarm, or null when monitoring is disabled"
  value       = local.enable_monitoring ? aws_cloudwatch_metric_alarm.high_cpu[0].alarm_name : null
}

# ─────────────────────────────────────────────────────────────────────────────
# Route53 record — CONDITIONALLY created
# ─────────────────────────────────────────────────────────────────────────────

output "dns_record_fqdn" {
  description = "FQDN of the Route53 alias record, or null when DNS creation is disabled"
  value       = var.create_dns_record ? aws_route53_record.alb[0].fqdn : null
}

# ─────────────────────────────────────────────────────────────────────────────
# VPC — conditionally created or looked up
# ─────────────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC in use (created or existing)"
  value       = local.vpc_id
}

# ─────────────────────────────────────────────────────────────────────────────
# Cluster metadata — always available
# ─────────────────────────────────────────────────────────────────────────────

output "subnet_ids" {
  description = "IDs of the two public subnets (one per AZ)"
  value       = aws_subnet.public[*].id
}


output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}


output "environment" {
  description = "The environment this cluster is deployed into"
  value       = var.environment
}

output "instance_type" {
  description = "EC2 instance type chosen for this environment"
  value       = local.instance_type
}

output "cluster_min_size" {
  description = "Minimum number of instances in the ASG"
  value       = local.min_size
}

output "cluster_max_size" {
  description = "Maximum number of instances in the ASG"
  value       = local.max_size
}
