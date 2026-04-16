# ─── ALB ─────────────────────────────────────────────────────────────────────
output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "Open this URL in your browser to reach the load-balanced application"
}

output "alb_security_group_id" {
  value       = module.alb.alb_security_group_id
  description = "Security group protecting the ALB"
}

output "target_group_arn" {
  value       = module.alb.target_group_arn
  description = "ALB target group — ASG registers instances here automatically"
}

# ─── EC2 / Launch Template ───────────────────────────────────────────────────
output "launch_template_id" {
  value       = module.ec2.launch_template_id
  description = "Launch Template ID used by the ASG"
}

output "launch_template_version" {
  value       = module.ec2.launch_template_version
  description = "Current Launch Template version"
}

output "instance_security_group_id" {
  value       = module.ec2.security_group_id
  description = "Security group attached to each EC2 instance"
}

# ─── Auto Scaling Group ──────────────────────────────────────────────────────
output "asg_name" {
  value       = module.asg.asg_name
  description = "Name of the Auto Scaling Group"
}

output "asg_arn" {
  value       = module.asg.asg_arn
  description = "ARN of the Auto Scaling Group"
}

output "scale_out_policy_arn" {
  value       = module.asg.scale_out_policy_arn
  description = "ARN of the CPU scale-out autoscaling policy"
}

output "scale_in_policy_arn" {
  value       = module.asg.scale_in_policy_arn
  description = "ARN of the CPU scale-in autoscaling policy"
}

output "cloudwatch_dashboard_name" {
  value       = module.asg.cloudwatch_dashboard_name
  description = "CloudWatch dashboard for monitoring CPU and instance count"
}
