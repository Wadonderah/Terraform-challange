##############################################################
# modules/compute/outputs.tf
##############################################################

output "alb_dns_name" {
  description = "DNS name of the ALB — paste into curl for functional verification"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "target_group_arn" {
  description = "ARN of the ALB Target Group — use with describe-target-health"
  value       = aws_lb_target_group.this.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.this.id
}
