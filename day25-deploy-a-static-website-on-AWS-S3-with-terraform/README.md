# Static Website on AWS S3 + CloudFront
## Day 25 — 30-Day Terraform Challenge

A production-grade static website deployed entirely through Terraform. One module call. Three environments. Zero console clicks.

**Live architecture:**
```
Browser → CloudFront (HTTPS, global CDN) → S3 Website Endpoint (HTTP origin)
```

---

## Quick Start

```bash
# 1. Clone and navigate
cd envs/dev

# 2. Update bucket name in terraform.tfvars (must be globally unique)
# bucket_name = "my-website-dev-123456789012"

# 3. Update backend config in main.tf with your S3 state bucket

# 4. Deploy
terraform init
terraform plan -out=dev.tfplan
terraform apply dev.tfplan

# 5. Get your URL
terraform output website_url
```

Or use the script:
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh dev apply
```

---

## What Gets Deployed

11 AWS resources per environment:

| Resource | Purpose |
|----------|---------|
| `aws_s3_bucket` | Stores website files |
| `aws_s3_bucket_versioning` | File version history (prod) |
| `aws_s3_bucket_server_side_encryption_configuration` | AES-256 at rest |
| `aws_s3_bucket_website_configuration` | Static website hosting |
| `aws_s3_bucket_public_access_block` | Controlled public read |
| `aws_s3_bucket_policy` | Public GetObject policy |
| `aws_s3_bucket_cors_configuration` | Browser CORS headers |
| `aws_s3_object.index` | Generated index.html |
| `aws_s3_object.error` | Generated error.html |
| `aws_s3_object.css` | Dark-mode stylesheet |
| `aws_cloudfront_distribution` | Global HTTPS CDN |

---

## Environment Comparison

| Setting | dev | staging | production |
|---------|-----|---------|-----------|
| Price class | PriceClass_100 | PriceClass_200 | PriceClass_All |
| Default TTL | 60s | 3600s | 86400s |
| Versioning | Off | On | On |
| force_destroy | ✅ true | ✅ true | ❌ false |
| Custom domain | No | Optional | Yes (when ready) |

---

## After Deploying New Content

```bash
# Invalidate CloudFront cache — required after S3 uploads
$(terraform output -raw cache_invalidation_command)
```

---

## Project Structure

```
.
├── modules/s3-static-website/   ← Reusable module (written once)
│   ├── main.tf                  ← All resource logic
│   ├── variables.tf             ← 15 validated inputs
│   ├── outputs.tf               ← URLs, IDs, commands
│   └── README.md                ← Executable documentation
├── envs/
│   ├── dev/                     ← Dev: cheap, fast, destructible
│   ├── staging/                 ← Staging: mirrors production behaviour
│   └── prod/                    ← Production: global, protected
├── .github/workflows/
│   └── deploy.yml               ← CI/CD: plan on PR, apply on merge
└── scripts/
    └── deploy.sh                ← Wrapper for common operations
```

---

## Built During

**30-Day Terraform Challenge** · AWS AI/ML UserGroup Kenya · Meru HashiCorp User Group · EveOps

`#30DayTerraformChallenge` `#Terraform` `#AWS` `#CloudFront` `#IaC`
