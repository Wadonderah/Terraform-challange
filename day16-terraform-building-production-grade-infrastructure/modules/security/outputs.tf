output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "ID of the web server security group."
  value       = aws_security_group.web.id
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile."
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_iam_role_arn" {
  description = "ARN of the EC2 IAM role."
  value       = aws_iam_role.ec2.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for encryption."
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "ID of the KMS key."
  value       = aws_kms_key.main.key_id
}
