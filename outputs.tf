# ALB DNS URL
output "alb_url" {
  description = "The URL of the Application Load Balancer"
  value       = "http://${aws_lb.alb.dns_name}"
}

# ASG Name
output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}
