# envs/dev/outputs.tf

output "website_url" {
  description = "Primary URL to access the website (HTTPS via CloudFront)"
  value       = module.static_website.website_url
}

output "cloudfront_domain_name" {
  description = "CloudFront *.cloudfront.net domain name"
  value       = module.static_website.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — use for cache invalidation"
  value       = module.static_website.cloudfront_distribution_id
}

output "cloudfront_status" {
  description = "CloudFront status: Deployed = live, InProgress = still propagating"
  value       = module.static_website.cloudfront_status
}

output "s3_website_url" {
  description = "Direct S3 website URL (HTTP only — for debugging only)"
  value       = module.static_website.s3_website_url
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = module.static_website.bucket_name
}

output "cache_invalidation_command" {
  description = "Run this after uploading new content to clear the CloudFront cache"
  value       = module.static_website.cache_invalidation_command
}

output "deployment_summary" {
  description = "Key configuration values for this deployment"
  value       = module.static_website.deployment_summary
}
