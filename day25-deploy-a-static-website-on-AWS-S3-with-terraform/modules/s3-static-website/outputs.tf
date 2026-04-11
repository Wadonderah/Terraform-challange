# modules/s3-static-website/outputs.tf

# ── S3 outputs ─────────────────────────────────────────────────────────────

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket (not the website endpoint)"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

output "website_endpoint" {
  description = "S3 static website endpoint (HTTP only — use CloudFront for HTTPS)"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

# ── CloudFront outputs ─────────────────────────────────────────────────────

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name. Use this URL to access your website via HTTPS. Format: d1234567890abc.cloudfront.net"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID. Used for cache invalidation: aws cloudfront create-invalidation --distribution-id <id> --paths '/*'"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID — used when creating Route53 alias records"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "cloudfront_status" {
  description = "Status of the CloudFront distribution. 'Deployed' = live globally. 'InProgress' = still propagating (wait 5–15 minutes)."
  value       = aws_cloudfront_distribution.website.status
}

output "cloudfront_price_class" {
  description = "Effective CloudFront price class being used"
  value       = aws_cloudfront_distribution.website.price_class
}

# ── Access URLs ────────────────────────────────────────────────────────────

output "website_url" {
  description = "The primary URL to access the website. Uses custom domain if configured, CloudFront domain otherwise."
  value = var.domain_name != null ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "s3_website_url" {
  description = "Direct S3 website URL (HTTP only, no CloudFront). For debugging only — use website_url for all real traffic."
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}

# ── Route53 outputs (conditional) ─────────────────────────────────────────

output "route53_record_fqdn" {
  description = "Fully qualified domain name of the Route53 A record (if custom domain configured)"
  value       = length(aws_route53_record.website_apex) > 0 ? aws_route53_record.website_apex[0].fqdn : null
}

# ── Operational outputs ────────────────────────────────────────────────────

output "cache_invalidation_command" {
  description = "AWS CLI command to invalidate the CloudFront cache after content updates"
  value       = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths '/*'"
}

output "deployment_summary" {
  description = "Human-readable summary of the deployment configuration"
  value = {
    environment   = var.environment
    bucket        = aws_s3_bucket.website.id
    price_class   = aws_cloudfront_distribution.website.price_class
    custom_domain = var.domain_name != null ? var.domain_name : "not configured"
    website_url   = var.domain_name != null ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.website.domain_name}"
    https_only    = true
    versioning    = var.enable_versioning
  }
}
