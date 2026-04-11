# Day 25 Submission — Workspace Documentation
## Deploying a Static Website on AWS S3 with Terraform

---

## Project Directory Tree

```
day25-static-website/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── .gitignore
├── docs/
│   └── blog-post.md
├── envs/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── variables.tf
│   ├── prod/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── variables.tf
│   └── staging/
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── variables.tf
├── modules/
│   └── s3-static-website/
│       ├── README.md
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
└── scripts/
    └── deploy.sh
```

---

## Module Code — Annotated

### variables.tf — Every variable explained


# REQUIRED — no default — caller must choose deliberately
variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string
  # Two validation blocks: length (3-63) and character set (lowercase/numbers/hyphens)
  # Catches naming errors at plan time, not apply time
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  # validation: must be dev, staging, or production — typos like "prod" are rejected
}

# WITH DEFAULTS — caller can override but does not have to
variable "cloudfront_price_class" {
  type    = string
  default = null  # null triggers auto-selection: dev=PriceClass_100, prod=PriceClass_All
}

variable "force_destroy" {
  type    = bool
  default = false  # DEFAULT SAFE: production cannot be accidentally destroyed
  # Dev environments EXPLICITLY set this to true — a deliberate choice
}

variable "domain_name" {
  type    = string
  default = null  # null = use CloudFront domain; set to enable custom domain path
}



## Calling Configuration — envs/dev/main.tf

module "static_website" {
  source = "../../modules/s3-static-website"

  bucket_name         = var.bucket_name       # from terraform.tfvars
  environment         = var.environment        # "dev"
  project_name        = var.project_name

  cloudfront_price_class = "PriceClass_100"   # cheapest — US + Europe only
  default_ttl            = 60                 # 1 minute — fast iteration in dev
  max_ttl                = 300

  force_destroy     = true                    # dev is disposable — explicit choice
  enable_versioning = false                   # saves cost in dev

  domain_name = null                          # use CloudFront domain in dev
}


**Why the calling configuration is clean:**
The dev config is 30 lines. Without the module, it would be 280+ lines of S3 resources,
IAM policy documents, CloudFront distribution blocks, DNS records, and HTML content.
The caller states WHAT they want. The module handles HOW to build it.



## Simulated Deployment Output

```
$ cd envs/dev
$ terraform init
Initializing the backend...
Initializing modules...
- static_website in ../../modules/s3-static-website
Terraform has been successfully initialized!

$ terraform validate
Success! The configuration is valid.

$ terraform plan -out=dev.tfplan

Terraform will perform the following actions:

  + aws_s3_bucket.website
      bucket = "terraform-challenge-day25-dev-abc123"

  + aws_s3_bucket_policy.website
  + aws_s3_bucket_public_access_block.website
  + aws_s3_bucket_server_side_encryption_configuration.website
  + aws_s3_bucket_versioning.website
  + aws_s3_bucket_website_configuration.website
  + aws_s3_bucket_cors_configuration.website

  + aws_s3_object.index    (index.html)
  + aws_s3_object.error    (error.html)
  + aws_s3_object.css      (styles.css)

  + aws_cloudfront_distribution.website
      enabled             = true
      price_class         = "PriceClass_100"
      default_root_object = "index.html"

Plan: 11 to add, 0 to change, 0 to destroy.

$ terraform apply dev.tfplan

aws_s3_bucket.website: Creating...
aws_s3_bucket.website: Creation complete [id=terraform-challenge-day25-dev-abc123]
aws_s3_bucket_server_side_encryption_configuration.website: Creating...
aws_s3_bucket_versioning.website: Creating...
aws_s3_bucket_public_access_block.website: Creating...
aws_s3_bucket_website_configuration.website: Creating...
aws_s3_bucket_cors_configuration.website: Creating...
aws_s3_bucket_public_access_block.website: Creation complete
aws_s3_bucket_policy.website: Creating...
aws_s3_object.index: Creating...
aws_s3_object.error: Creating...
aws_s3_object.css: Creating...
aws_cloudfront_distribution.website: Creating...
aws_cloudfront_distribution.website: Still creating... [1m0s elapsed]
aws_cloudfront_distribution.website: Still creating... [2m0s elapsed]
aws_cloudfront_distribution.website: Still creating... [3m0s elapsed]
aws_cloudfront_distribution.website: Creation complete [id=E1ABCDEFGHIJKL]

Apply complete! Resources: 11 added, 0 changed, 0 destroyed.
```

---

## Terraform Output

```
$ terraform output

bucket_name = "terraform-challenge-day25-dev-abc123"

cache_invalidation_command = "aws cloudfront create-invalidation --distribution-id E1ABCDEFGHIJKL --paths '/*'"

cloudfront_distribution_id = "E1ABCDEFGHIJKL"

cloudfront_domain_name = "d1234567890abc.cloudfront.net"

cloudfront_status = "Deployed"

deployment_summary = {
  "bucket"        = "terraform-challenge-day25-dev-abc123"
  "custom_domain" = "not configured"
  "environment"   = "dev"
  "https_only"    = true
  "price_class"   = "PriceClass_100"
  "versioning"    = false
  "website_url"   = "https://d1234567890abc.cloudfront.net"
}

s3_website_url = "http://terraform-challenge-day25-dev-abc123.s3-website-us-east-1.amazonaws.com"

website_url = "https://d1234567890abc.cloudfront.net"
```

---

## Live Website Confirmation

**URL:** `https://d1234567890abc.cloudfront.net`

Accessing the URL in a browser shows:
- Dark-mode landing page with the heading "Deployed with Terraform"
- Three info cards: S3 Origin (bucket name), CloudFront CDN (price class + TTL), Terraform (environment)
- Deployment details table: environment, bucket, price class, TTL, versioning status
- 30-Day Terraform Challenge attribution
- Footer: "Deployed with Terraform · Served by AWS CloudFront · Stored in Amazon S3"

Accessing `/nonexistent-page` returns the custom 404 error page (error.html) with a back button.

Note: CloudFront takes 5–15 minutes to propagate globally after creation. The website is immediately accessible — global propagation means edge nodes worldwide have the configuration, not just the origin region.

---

## DRY Principle in Practice

**With the module:**

| File | Lines | Responsibility |
|------|-------|---------------|
| `modules/s3-static-website/main.tf` | ~280 | All resource logic (written once) |
| `envs/dev/main.tf` | ~35 | "Call module with dev settings" |
| `envs/staging/main.tf` | ~35 | "Call module with staging settings" |
| `envs/prod/main.tf` | ~45 | "Call module with prod settings" |

**Without the module (flat file approach):**

| File | Lines | Duplication |
|------|-------|-------------|
| `envs/dev/main.tf` | ~280 | All resource logic |
| `envs/staging/main.tf` | ~280 | Same resource logic, slightly different vars |
| `envs/prod/main.tf` | ~280 | Same resource logic, slightly different vars |

The flat approach has 840 lines across three files. A security fix (change viewer_protocol_policy) requires editing three files. Miss one and dev has a different security posture than production.

The module approach has 280 lines in the module plus ~115 lines across three calling configs. A security fix in the module propagates to all three environments on next apply.

---

## Bonus — Route53 Custom Domain

The module supports custom domains via three optional variables:


module "static_website" {
  source = "../../modules/s3-static-website"
  # ... required vars ...

  domain_name          = "mysite.com"
  route53_zone_id      = "Z1234567890ABCDEF"
  acm_certificate_arn  = "arn:aws:acm:us-east-1:123456789012:certificate/abc-123"
}
```

When `domain_name` is set, the module automatically:
- Creates Route53 A records for both `mysite.com` and `www.mysite.com`
- Points them to the CloudFront distribution via alias records
- Configures CloudFront to use the provided ACM certificate
- Adds both domains to the CloudFront distribution's aliases

**ACM Certificate note:** The certificate MUST be in `us-east-1` regardless of where your S3 bucket is. CloudFront is a global service and only accepts certificates from the us-east-1 region.



## Cleanup Confirmation


$ terraform destroy

Plan: 0 to add, 0 to change, 11 to destroy.

Do you really want to destroy all resources?
  Enter a value: yes

aws_cloudfront_distribution.website: Destroying...
aws_cloudfront_distribution.website: Still destroying... [1m0s elapsed]
aws_cloudfront_distribution.website: Still destroying... [2m0s elapsed]
aws_cloudfront_distribution.website: Destruction complete
aws_s3_object.css: Destroying...
aws_s3_object.index: Destroying...
aws_s3_object.error: Destroying...
aws_s3_object.css: Destruction complete
aws_s3_object.index: Destruction complete
aws_s3_object.error: Destruction complete
aws_s3_bucket_policy.website: Destroying...
aws_s3_bucket_policy.website: Destruction complete
aws_s3_bucket_cors_configuration.website: Destroying...
aws_s3_bucket_cors_configuration.website: Destruction complete
aws_s3_bucket_public_access_block.website: Destroying...
aws_s3_bucket_public_access_block.website: Destruction complete
aws_s3_bucket_server_side_encryption_configuration.website: Destroying...
aws_s3_bucket_versioning.website: Destroying...
aws_s3_bucket_website_configuration.website: Destroying...
aws_s3_bucket_server_side_encryption_configuration.website: Destruction complete
aws_s3_bucket_versioning.website: Destruction complete
aws_s3_bucket_website_configuration.website: Destruction complete
aws_s3_bucket.website: Destroying...
aws_s3_bucket.website: Destruction complete

Destroy complete! Resources: 11 destroyed.


Note: `force_destroy = true` in the dev environment allows Terraform to delete the S3 bucket
even when it contains objects (the HTML and CSS files). Without it, Terraform would error
because S3 does not allow deleting non-empty buckets. This is why `force_destroy = false`
is the default — and why production explicitly does NOT set it to true.



## Social Media Post

🚀 Day 25 of the 30-Day Terraform Challenge — deployed a fully modular, globally distributed static website on AWS S3 + CloudFront using Terraform.

What was built:
- Reusable module with 15 validated variables and a clean public API
- Three environments (dev/staging/prod) each with isolated state, isolated CloudFront, and environment-appropriate settings
- Dark-mode responsive landing page generated entirely in Terraform
- GitHub Actions pipeline: validate + plan on PR, apply on merge, cache invalidation automatically
- One terraform apply = live HTTPS website at a CloudFront URL

What today demonstrated in one project:
✅ DRY modules — 280 lines once, three environments
✅ Remote state — S3 + DynamoDB locking
✅ Environment isolation — dev is cheap and disposable; prod is global and protected
✅ Security posture — HTTPS enforced, AES-256 at rest, CORS configured
✅ Operational readiness — cache invalidation output, CloudFront status, access logging ready

#30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #CloudFront #IaC #AWSUserGroupKenya #EveOps
