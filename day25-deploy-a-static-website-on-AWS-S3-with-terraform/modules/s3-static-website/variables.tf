# modules/s3-static-website/variables.tf
# Every variable is documented, validated, and has a sensible default where appropriate.
# Variables with no default are REQUIRED — they force the caller to make a deliberate choice.

# ── Core identity ──────────────────────────────────────────────────────────

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket. S3 names are global across all AWS accounts — append your account ID or a random suffix to guarantee uniqueness."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9\\-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must contain only lowercase letters, numbers, and hyphens, and must start and end with a letter or number."
  }
}

variable "environment" {
  description = "Deployment environment. Controls cost/performance trade-offs: dev uses PriceClass_100 (cheapest), production uses PriceClass_All (global)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "project_name" {
  description = "Short identifier for this project — used in tags, resource names, and descriptions."
  type        = string
  default     = "static-website"

  validation {
    condition     = can(regex("^[a-z0-9\\-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

# ── Website content ────────────────────────────────────────────────────────

variable "index_document" {
  description = "The default document served when a visitor accesses the root URL or a directory."
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "The document served for 4xx errors (file not found, etc.)."
  type        = string
  default     = "error.html"
}

variable "website_title" {
  description = "Title displayed in the browser tab and H1 heading on the generated index page."
  type        = string
  default     = "Deployed with Terraform"
}

variable "website_description" {
  description = "Subtitle paragraph displayed on the generated index page."
  type        = string
  default     = "A globally distributed static website — built in one terraform apply."
}

# ── CloudFront performance ─────────────────────────────────────────────────

variable "cloudfront_price_class" {
  description = <<-DESC
    CloudFront price class controls which edge locations serve your content.
    PriceClass_100 = US, Canada, Europe only (cheapest — good for dev)
    PriceClass_200 = adds Asia, Middle East, Africa
    PriceClass_All = all edge locations globally (most expensive — use for production)
    If not set, defaults based on environment: dev=PriceClass_100, production=PriceClass_All.
  DESC
  type        = string
  default     = null  # null = auto-select based on environment

  validation {
    condition = var.cloudfront_price_class == null || contains(
      ["PriceClass_100", "PriceClass_200", "PriceClass_All"],
      coalesce(var.cloudfront_price_class, "PriceClass_100")
    )
    error_message = "cloudfront_price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "default_ttl" {
  description = "Default cache TTL in seconds for CloudFront. 3600 = 1 hour. Lower values mean fresher content but more origin requests."
  type        = number
  default     = 3600

  validation {
    condition     = var.default_ttl >= 0 && var.default_ttl <= 86400
    error_message = "default_ttl must be between 0 and 86400 seconds (24 hours)."
  }
}

variable "max_ttl" {
  description = "Maximum cache TTL in seconds. Objects will be refreshed from origin at least this often."
  type        = number
  default     = 86400  # 24 hours
}

# ── Custom domain (optional) ───────────────────────────────────────────────

variable "domain_name" {
  description = "Custom domain name (e.g., example.com). Leave null to use the CloudFront *.cloudfront.net domain. Requires Route53 zone and ACM certificate."
  type        = string
  default     = null
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for the custom domain. Required when domain_name is set."
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ARN of an ACM certificate in us-east-1 for the custom domain. CloudFront requires us-east-1 certificates regardless of bucket region. Required when domain_name is set."
  type        = string
  default     = null
}

# ── Security ───────────────────────────────────────────────────────────────

variable "enable_versioning" {
  description = "Enable S3 versioning. Recommended for production — allows recovery of accidentally deleted or overwritten files."
  type        = bool
  default     = false
}

variable "log_bucket_name" {
  description = "Name of S3 bucket to receive CloudFront access logs. Leave null to disable logging."
  type        = string
  default     = null
}

# ── Lifecycle ──────────────────────────────────────────────────────────────

variable "force_destroy" {
  description = "Allow terraform destroy to delete the bucket even when it contains objects. Set true for dev/staging. NEVER set true for production."
  type        = bool
  default     = false
}

# ── Tagging ────────────────────────────────────────────────────────────────

variable "tags" {
  description = "Additional tags merged onto all resources. Standard tags (Environment, ManagedBy, Project) are always applied automatically."
  type        = map(string)
  default     = {}
}
