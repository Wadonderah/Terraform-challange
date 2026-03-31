##############################################################################
# Outputs — Day 14 Multi-Region Deployment
##############################################################################

output "primary_bucket_id" {
  description = "Name of the primary S3 bucket (us-east-1)"
  value       = aws_s3_bucket.primary.id
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket"
  value       = aws_s3_bucket.primary.arn
}

output "replica_bucket_id" {
  description = "Name of the replica S3 bucket (us-west-2)"
  value       = aws_s3_bucket.replica.id
}

output "replica_bucket_arn" {
  description = "ARN of the replica S3 bucket"
  value       = aws_s3_bucket.replica.arn
}

output "replication_role_arn" {
  description = "ARN of the IAM role used for S3 replication"
  value       = aws_iam_role.replication.arn
}

output "account_id" {
  description = "AWS account ID where resources were deployed"
  value       = data.aws_caller_identity.current.account_id
}

output "deployment_summary" {
  description = "Human-readable summary of what was deployed"
  value = <<-EOT
    ╔══════════════════════════════════════════════════════════════╗
    ║          Day 14 — Multi-Region S3 Replication               ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Primary  : ${aws_s3_bucket.primary.id}
    ║  Region   : ${var.primary_region}
    ║  Replica  : ${aws_s3_bucket.replica.id}
    ║  Region   : ${var.replica_region}
    ║  IAM Role : ${aws_iam_role.replication.name}
    ╚══════════════════════════════════════════════════════════════╝
  EOT
}
