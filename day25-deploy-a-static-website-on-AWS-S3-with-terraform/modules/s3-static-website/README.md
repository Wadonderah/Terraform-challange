# Module: s3-static-website

## What it does

Deploys a production-grade static website on AWS using S3 + CloudFront with a single module call.

**Architecture:**
```
Browser → CloudFront (HTTPS, global CDN) → S3 Website Endpoint (HTTP origin)
```

Everything is included:
- S3 bucket with website hosting, AES-256 encryption, optional versioning
- CloudFront distribution with HTTPS enforcement, compression, custom error pages
- Dark-mode responsive landing page and 404 error page generated automatically
- CSS stylesheet with card grid layout
- CORS configuration
- Optional Route53 DNS records for custom domains

---

## Usage

### Minimal (dev)
```hcl
module "static_website" {
  source = "../../modules/s3-static-website"

  bucket_name = "my-website-dev-abc123"
  environment = "dev"
}
```

### Full (production with custom domain)
```hcl
module "static_website" {
  source = "../../modules/s3-static-website"

  bucket_name         = "mycompany-website-prod"
  environment         = "production"
  project_name        = "company-website"
  website_title       = "My Company"
  website_description = "Building something great."

  domain_name          = "mycompany.com"
  route53_zone_id      = "Z1234567890"
  acm_certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"

  enable_versioning    = true
  force_destroy        = false

  cloudfront_price_class = "PriceClass_All"
  default_ttl            = 86400
  max_ttl                = 604800

  tags = {
    Owner      = "platform-team"
    CostCenter = "cc-100"
    Repo       = "github.com/myorg/website"
  }
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `bucket_name` | string | — | yes | Globally unique S3 bucket name |
| `environment` | string | — | yes | dev / staging / production |
| `project_name` | string | `"static-website"` | no | Identifier used in tags |
| `index_document` | string | `"index.html"` | no | Root document |
| `error_document` | string | `"error.html"` | no | 404 error document |
| `website_title` | string | `"Deployed with Terraform"` | no | Page H1 title |
| `website_description` | string | `"A globally distributed..."` | no | Page subtitle |
| `cloudfront_price_class` | string | null (auto) | no | PriceClass_100/200/All |
| `default_ttl` | number | `3600` | no | Default cache TTL (seconds) |
| `max_ttl` | number | `86400` | no | Maximum cache TTL (seconds) |
| `domain_name` | string | null | no | Custom domain (e.g., example.com) |
| `route53_zone_id` | string | null | no | Route53 zone for DNS records |
| `acm_certificate_arn` | string | null | no | ACM cert ARN (must be us-east-1) |
| `enable_versioning` | bool | `false` | no | S3 versioning |
| `log_bucket_name` | string | null | no | CloudFront access log destination |
| `force_destroy` | bool | `false` | no | Allow non-empty bucket destroy |
| `tags` | map(string) | `{}` | no | Additional resource tags |

---

## Outputs

| Name | Description |
|------|-------------|
| `website_url` | Primary URL (custom domain if set, CloudFront otherwise) |
| `cloudfront_domain_name` | CloudFront *.cloudfront.net domain |
| `cloudfront_distribution_id` | For cache invalidation |
| `cloudfront_status` | "Deployed" or "InProgress" |
| `bucket_name` | S3 bucket name |
| `cache_invalidation_command` | Ready-to-run AWS CLI invalidation command |
| `deployment_summary` | Map of key configuration values |

---

## Design decisions

**Why HTTP origin to CloudFront?**
S3 website endpoints only support HTTP. The CloudFront → browser connection is HTTPS (enforced by `redirect-to-https`). This is the correct and widely-used architecture for S3-based websites. S3 REST endpoints support HTTPS but lose static website features (index/error documents, redirects).

**Why auto-select price class?**
Dev environments waste money sending traffic through edge locations in Asia-Pacific. `PriceClass_100` (US + Europe only) cuts CloudFront cost by ~40% for development. Production gets `PriceClass_All` automatically.

**Why force_destroy defaults to false?**
Accidental `terraform destroy` on production should never succeed if the bucket has content. `force_destroy = true` is intentional and explicit — callers must set it deliberately.

**Why generate HTML in the module?**
This module is self-contained — it deploys a working website on first apply without requiring pre-uploaded files. Real projects would replace `aws_s3_object.index` with a `for_each` loop uploading a local build directory.

---

## Upgrading content after deploy

After pushing new content to S3, invalidate the CloudFront cache:
```bash
# The output already gives you this command:
terraform output -raw cache_invalidation_command | bash

# Or manually:
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths '/*'
```
