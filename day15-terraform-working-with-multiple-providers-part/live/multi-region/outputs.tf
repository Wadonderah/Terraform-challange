# live/multi-region/outputs.tf

output "primary_bucket_id" {
  description = "Name of the primary S3 bucket."
  value       = module.multi_region_app.primary_bucket_id
}

output "primary_bucket_arn" {
  description = "ARN of the primary S3 bucket."
  value       = module.multi_region_app.primary_bucket_arn
}

output "replica_bucket_id" {
  description = "Name of the replica S3 bucket."
  value       = module.multi_region_app.replica_bucket_id
}

output "replica_bucket_arn" {
  description = "ARN of the replica S3 bucket."
  value       = module.multi_region_app.replica_bucket_arn
}

output "replication_role_arn" {
  description = "ARN of the IAM replication role."
  value       = module.multi_region_app.replication_role_arn
}
