##############################################################
# modules/security/outputs.tf
##############################################################

output "alb_sg_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "instance_sg_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.instance.id
}
