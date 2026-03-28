###############################################################################
# modules/webserver-cluster/outputs.tf
###############################################################################

output "alb_dns_name" {
  description = "Public DNS name of the ALB — use this to curl the app"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB"
  value       = aws_lb.main.arn
}

output "active_environment" {
  description = "Which target group is currently receiving live traffic"
  value       = var.active_environment
}

output "blue_asg_name" {
  description = "Name of the blue Auto Scaling Group"
  value       = aws_autoscaling_group.blue.name
}

output "green_asg_name" {
  description = "Name of the green Auto Scaling Group"
  value       = aws_autoscaling_group.green.name
}

output "blue_launch_template_name" {
  description = "Name of the blue Launch Template (includes random_id for uniqueness)"
  value       = aws_launch_template.blue.name
}

output "green_launch_template_name" {
  description = "Name of the green Launch Template"
  value       = aws_launch_template.green.name
}

output "traffic_loop_command" {
  description = "Paste this into a second terminal to monitor traffic during deployments"
  value       = "while true; do curl -s http://${aws_lb.main.dns_name} | grep -o '<div class=\"version\">[^<]*</div>'; sleep 2; done"
}
