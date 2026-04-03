##############################################################
# modules/services/webserver-cluster/outputs.tf
# Day 18: Automated Testing
##############################################################

output "alb_dns_name" {
  description = "DNS name of the ALB — used by integration and E2E tests to assert HTTP response"
  value       = aws_lb.example.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.example.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.example.name
}

output "alb_sg_id" {
  description = "Security group ID attached to the ALB"
  value       = aws_security_group.alb.id
}

output "instance_sg_id" {
  description = "Security group ID attached to EC2 instances"
  value       = aws_security_group.instance.id
}

output "cluster_name" {
  description = "Cluster name used as resource prefix"
  value       = var.cluster_name
}

output "server_port" {
  description = "Port the web server listens on"
  value       = var.server_port
}
