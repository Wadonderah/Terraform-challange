# modules/compute/asg-rolling-deploy/outputs.tf

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "instance_security_group_id" {
  description = "Security group ID attached to ASG instances"
  value       = aws_security_group.instance.id
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}
