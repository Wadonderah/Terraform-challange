output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer. Use this to access the cluster or create a CNAME in Route53."
  value       = aws_lb.webserver.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB. Needed if you want to attach WAF rules or additional listeners outside this module."
  value       = aws_lb.webserver.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group. Use this to attach additional scaling policies or query instance health."
  value       = aws_autoscaling_group.webserver.name
}

output "instance_security_group_id" {
  description = "ID of the instance security group. Expose this so callers can add extra ingress rules (e.g. bastion access) without modifying the module."
  value       = aws_security_group.instance.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group. Useful for whitelisting the ALB in other security groups downstream."
  value       = aws_security_group.alb.id
}
