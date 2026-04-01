output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB (for Route53 alias records)."
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the ALB target group."
  value       = aws_lb_target_group.main.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group."
  value       = aws_autoscaling_group.main.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group."
  value       = aws_autoscaling_group.main.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template."
  value       = aws_launch_template.main.id
}

output "scale_out_policy_arn" {
  description = "ARN of the scale-out autoscaling policy."
  value       = aws_autoscaling_policy.scale_out.arn
}

output "scale_in_policy_arn" {
  description = "ARN of the scale-in autoscaling policy."
  value       = aws_autoscaling_policy.scale_in.arn
}
