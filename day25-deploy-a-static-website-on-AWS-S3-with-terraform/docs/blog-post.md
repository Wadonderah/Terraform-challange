# Deploying a Static Website on AWS S3 with Terraform: A Complete Guide
## Day 25 of the 30-Day Terraform Challenge

*This is the project where everything from the last 24 days comes together in one deployable package. Modular code. Remote state. DRY configuration. Environment isolation. Consistent tagging. Version-controlled infrastructure. Today you build something you can actually put in a portfolio.*

---

## What You Will Build

A globally distributed static website served over HTTPS via CloudFront, backed by S3, deployed entirely through Terraform — with zero console clicks. The architecture:

```
Browser → CloudFront (HTTPS, global CDN) → S3 Website Endpoint (HTTP origin)
```

By the end, you will have:
- A live HTTPS website at a *.cloudfront.net URL
- A reusable module you can call for dev, staging, and production with different settings
- Remote state locked in S3 + DynamoDB
- A GitHub Actions pipeline that plans on PR and applies on merge
- A cache invalidation command ready to run after every content update

---

## Why Module, Not Flat File?

Before diving into code, let me answer the question most beginners ask: why not just put everything in one `main.tf`?

Here is what a flat, non-modular approach looks like:

```
dev/
└── main.tf    ← 300 lines of S3, CloudFront, policy, objects, everything

staging/
└── main.tf    ← same 300 lines, slightly different variables (copy-paste)

prod/
└── main.tf    ← same 300 lines again (copy-paste)
```

Three copies of 300 lines means:
- A bug fix must be applied in three places
- A security improvement must be applied in three places
- A new developer reads the production config and has no idea what is "important" vs "boilerplate"
- When CloudFront releases a new feature, you update it three times

The modular approach:

```
modules/s3-static-website/
├── main.tf        ← 300 lines of infrastructure logic (written ONCE)
├── variables.tf   ← the public API of the module
└── outputs.tf     ← what the module exposes

envs/dev/main.tf    ← 30 lines: "call the module with these settings"
envs/staging/main.tf ← 30 lines: "call the module with these settings"
envs/prod/main.tf   ← 30 lines: "call the module with these settings"
```

The calling configuration is clean because all the complexity lives in the module. When you read `envs/prod/main.tf`, you see the intent — environment, bucket name, cache settings, custom domain — not the implementation.

That is the DRY principle in practice.

---

## Project Structure

```
day25-static-website/
├── .github/
│   └── workflows/
│       └── deploy.yml              ← CI/CD pipeline (validate + plan on PR, apply on merge)
├── modules/
│   └── s3-static-website/
│       ├── main.tf                 ← S3 + CloudFront + DNS resources
│       ├── variables.tf            ← Module input API (15 variables, all validated)
│       ├── outputs.tf              ← What the module exposes (URLs, IDs, commands)
│       └── README.md               ← Executable documentation
├── envs/
│   ├── dev/
│   │   ├── main.tf                 ← Calls module with dev settings
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars        ← Dev-specific values
│   ├── staging/
│   │   └── ... (same structure)
│   └── prod/
│       └── ... (same structure)
├── scripts/
│   └── deploy.sh                   ← Wrapper script for common workflows
├── .gitignore
└── README.md
```

---

## The Module in Detail

### variables.tf — the Public API

Every variable is documented with a description, has an appropriate type constraint, and where applicable includes a validation block. Required variables (those with no default) force the caller to make a deliberate choice.

Key design decisions:

**`bucket_name` has two validation blocks** — one for length (3–63 characters, S3 requirement) and one for character set (lowercase, numbers, hyphens only). This catches naming errors at `terraform plan` rather than at `terraform apply` when AWS rejects the bucket creation.

**`cloudfront_price_class` defaults to null** — and the module auto-selects the right value based on environment:
```hcl
effective_price_class = coalesce(
  var.cloudfront_price_class,
  var.environment == "production" ? "PriceClass_All" : "PriceClass_100"
)
```
Dev gets the cheapest edge network (US + Europe). Production gets global. You can always override with an explicit value.

**`force_destroy` defaults to false** — protecting production from accidental `terraform destroy`. The dev environment explicitly sets `force_destroy = true` because that is the intentional, deliberate choice for a disposable environment.

### main.tf — the Implementation

#### S3 Resources

The bucket is private — no direct public access from the internet. Everything goes through CloudFront. But S3 website hosting requires the bucket policy to allow `s3:GetObject` for `*` (all principals) — this is the correct architecture, not a security flaw. The access control is at the CloudFront layer (HTTPS enforcement, geo restrictions, WAF if needed).

```hcl
resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

Server-side encryption (AES-256) is always enabled — even for a public static website. Encryption at rest is a baseline security requirement regardless of content sensitivity.

#### CloudFront Distribution

The distribution connects to the S3 website endpoint via a custom origin (HTTP). The viewer-facing connection is HTTPS, enforced via `viewer_protocol_policy = "redirect-to-https"`.

Two cache behaviours:
1. **Default** — for HTML files, with configurable TTL (1 minute in dev, 24 hours in prod)
2. **CSS/static assets** — always cached for 24 hours minimum (static files change rarely)

Custom error responses for 403 and 404 both serve the error page with a 404 status code — this prevents CloudFront's default XML error page from being shown to users.

#### The Generated Website

The module generates a production-quality dark-mode HTML page directly in Terraform using `templatefile`-style locals. The page includes:
- A card grid showing the three layers (S3, CloudFront, Terraform)
- A deployment details table showing the live configuration values
- Responsive CSS with hover effects and gradient typography
- A separate 404 error page with a back button

In a real project, you would replace `aws_s3_object.index` with a `for_each` loop over your build output directory. The generated page is there so the module deploys a working, visible website on first apply — no pre-existing files required.

### outputs.tf — What the Module Exposes

The most important output is `cache_invalidation_command`:
```
aws cloudfront create-invalidation --distribution-id E1EXAMPLE --paths '/*'
```

After deploying new content to S3, CloudFront will serve cached old versions until the TTL expires — unless you invalidate. This output gives you the exact command to run, pre-populated with the correct distribution ID.

`deployment_summary` is a map output — useful for CI pipelines that need to inspect configuration without parsing individual outputs.

---

## Environment Isolation

Each environment has its own:
- State file (separate S3 key)
- DynamoDB lock (separate lock entry)
- Bucket (separate S3 bucket)
- CloudFront distribution
- Variable values (`terraform.tfvars`)

| Setting | Dev | Staging | Production |
|---------|-----|---------|-----------|
| Price class | PriceClass_100 | PriceClass_200 | PriceClass_All |
| Default TTL | 60s | 3600s | 86400s |
| Versioning | Off | On | On |
| force_destroy | true | true | false |
| Custom domain | No | Optional | Yes (when ready) |

Dev is cheap and fast to iterate. Production is global and protected.

---

## Deployment Step by Step

### Prerequisites
- AWS credentials configured (or OIDC role set up for CI)
- S3 bucket for remote state + DynamoDB table for locking (see the Day 22 bootstrap module)
- Terraform 1.5+

### Step 1: Update terraform.tfvars

```hcl
# envs/dev/terraform.tfvars
bucket_name = "my-website-dev-123456789012"  # must be globally unique
```

Append your AWS account ID to guarantee uniqueness without a random suffix.

### Step 2: Update backend configuration

In `envs/dev/main.tf`, update the backend block:
```hcl
backend "s3" {
  bucket         = "your-actual-state-bucket"
  dynamodb_table = "your-actual-lock-table"
  ...
}
```

### Step 3: Deploy

```bash
cd envs/dev
terraform init
terraform validate
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
```

Or use the provided script:
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh dev plan
./scripts/deploy.sh dev apply
```

### Step 4: Access your website

```bash
terraform output website_url
# https://d1234567890abc.cloudfront.net
```

Open the URL in your browser. If you see "This distribution is not yet available," wait 5–15 minutes — CloudFront is propagating globally to edge locations.

### Step 5: Clean up

```bash
./scripts/deploy.sh dev destroy
```

Or:
```bash
cd envs/dev && terraform destroy
```

CloudFront distributions accumulate charges. Destroy after verifying unless you are keeping the site live.

---

## The DRY Principle — Demonstrated

**Without the module:** Changing `viewer_protocol_policy` from `redirect-to-https` to `allow-all` requires editing 3 files (dev, staging, prod), with the risk of missing one and having inconsistent security posture.

**With the module:** Change it in one place (`modules/s3-static-website/main.tf`) and all three environments inherit the fix on their next apply.

The module's `variables.tf` is its public API contract — callers can customise what the module exposes through variables. Everything else is an implementation detail hidden inside the module.

---

## Remote State — Why It Matters

Without remote state:
- `terraform.tfstate` lives on one developer's laptop
- Another developer runs apply from their machine — no locking — both overwrites happen — state is corrupted
- Laptop is lost — state is gone — nobody knows what Terraform manages
- State file contains RDS password in plaintext — laptop = credential leak

With S3 + DynamoDB remote state:
- State lives in S3 (encrypted, versioned, access-controlled)
- DynamoDB prevents concurrent applies from two team members
- If apply fails, the state file is preserved for recovery
- No secrets on developer laptops

This is not theoretical. State corruption from concurrent applies is one of the most common Terraform incidents at teams that skip the remote backend step.

---

## What This Demonstrates to Leadership and Recruiters

This single project demonstrates:

1. **Modular thinking** — complexity abstracted behind a clean API
2. **Environment isolation** — dev/staging/prod each has its own state, values, and guardrails
3. **DRY infrastructure** — one module serves three environments without copy-paste
4. **Security posture** — encryption at rest, HTTPS enforcement, proper IAM policy scoping
5. **Operational readiness** — cache invalidation command, CloudFront status output, access logging
6. **CI/CD integration** — GitHub Actions pipeline with plan-on-PR and apply-on-merge
7. **Tagging discipline** — every resource tagged consistently for cost allocation and compliance

Everything a platform engineering team looks for in a mid-to-senior cloud engineer candidate.

---

*Day 25 complete. A live, globally distributed website deployed in one terraform apply.*

*#30DayTerraformChallenge #TerraformChallenge #Terraform #AWS #CloudFront #S3 #IaC #AWSUserGroupKenya #EveOps*
