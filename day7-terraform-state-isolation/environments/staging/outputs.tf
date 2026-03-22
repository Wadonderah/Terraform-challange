
output "vpc_id" {
  description = "VPC ID for staging environment"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Subnet ID for staging environment"
  value       = aws_subnet.public.id
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}
