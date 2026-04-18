output "asg_name" {
  value       = aws_autoscaling_group.web.name
  description = "Name of the Auto Scaling Group"
}

output "asg_arn" {
  value       = aws_autoscaling_group.web.arn
  description = "ARN of the Auto Scaling Group"
}

output "instance_security_group_id" {
  value       = aws_security_group.instance.id
  description = "Security group ID attached to EC2 instances — passed to RDS module"
}

output "launch_template_id" {
  value       = aws_launch_template.web.id
  description = "ID of the EC2 Launch Template"
}

output "scale_out_policy_arn" {
  value       = aws_autoscaling_policy.scale_out.arn
  description = "ARN of the scale-out autoscaling policy"
}

output "scale_in_policy_arn" {
  value       = aws_autoscaling_policy.scale_in.arn
  description = "ARN of the scale-in autoscaling policy"
}
