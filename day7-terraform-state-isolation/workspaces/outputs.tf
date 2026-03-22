
output "vpc_id" {
  description = "VPC ID for the current workspace"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "instance_type" {
  description = "Instance type deployed in this workspace"
  value       = aws_instance.web.instance_type
}

output "environment" {
  description = "Current Terraform workspace (environment)"
  value       = terraform.workspace
}

output "public_ip" {
  description = "Public IP of the web instance"
  value       = aws_instance.web.public_ip
}
