output "alb_dns_name" {
  description = "DNS name of the ALB."
  value       = module.compute.alb_dns_name
}

output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = module.compute.asg_name
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.networking.vpc_id
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL."
  value       = module.monitoring.dashboard_url
}
