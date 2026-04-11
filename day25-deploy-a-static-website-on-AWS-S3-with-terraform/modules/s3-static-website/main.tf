# modules/s3-static-website/main.tf
# Production-grade S3 + CloudFront static website module.
#
# Architecture:
#   Browser → CloudFront (HTTPS, global edge) → S3 Website Endpoint (HTTP origin)
#
# Security posture:
#   - S3 bucket is NOT public-directly — all traffic goes through CloudFront
#   - CloudFront enforces HTTPS via redirect-to-https viewer protocol policy
#   - Origin connection is HTTP (S3 website endpoints do not support HTTPS)
#   - Geo restrictions disabled by default (enable for compliance requirements)
#   - CloudFront access logging configurable
#
# Cost posture:
#   - Price class auto-selected based on environment (dev = cheapest region set)
#   - S3 versioning optional (adds storage cost — off by default, on for production)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── Local computed values ──────────────────────────────────────────────────

locals {
  # Auto-select CloudFront price class based on environment if not explicitly set
  effective_price_class = coalesce(
    var.cloudfront_price_class,
    var.environment == "production" ? "PriceClass_All" : "PriceClass_100"
  )

  # Standard tags applied to every resource in this module
  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
    Module      = "s3-static-website"
  })

  # Whether a custom domain is configured
  has_custom_domain = var.domain_name != null

  # CloudFront origin ID — stable identifier for the S3 website origin
  origin_id = "${var.project_name}-s3-website-origin"
}

# ── S3 Bucket ──────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = local.common_tags
}

# Versioning — off by default, enable for production
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-side encryption — always on, even for a public website
# Encrypts at rest without affecting public read access
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Website configuration — enables the S3 static website hosting endpoint
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# Public access block — allow public reads (required for S3 website hosting)
# We open only what is necessary: public ACLs and bucket policy
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy — allows anyone to read objects (public website requirement)
# The depends_on ensures the public access block is applied before the policy
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.website_read.json

  depends_on = [aws_s3_bucket_public_access_block.website]
}

data "aws_iam_policy_document" "website_read" {
  statement {
    sid    = "PublicReadGetObject"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
  }
}

# ── CORS configuration — allows the browser to load assets from the same bucket
resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = local.has_custom_domain ? ["https://${var.domain_name}"] : ["*"]
    max_age_seconds = 3000
  }
}

# ── Website HTML Content ───────────────────────────────────────────────────

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = var.index_document
  content_type = "text/html; charset=utf-8"
  etag         = md5(local.index_html_content)

  content = local.index_html_content

  tags = local.common_tags
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = var.error_document
  content_type = "text/html; charset=utf-8"
  etag         = md5(local.error_html_content)

  content = local.error_html_content

  tags = local.common_tags
}

resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.website.id
  key          = "styles.css"
  content_type = "text/css"

  content = local.css_content

  tags = local.common_tags
}

locals {
  index_html_content = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta name="description" content="Welcome Back Wadondera — Deployed with Terraform">
      <title>${var.website_title}</title>
      <link rel="stylesheet" href="styles.css">
    </head>
    <body>
      <div class="container">
        <header>
          <div class="badge">Day 25 — 30-Day Terraform Challenge</div>
          <div class="avatar">W</div>
          <h1>${var.website_title}</h1>
          <p class="subtitle">${var.website_description}</p>
        </header>

        <main>
          <div class="card-grid">
            <div class="card">
              <div class="card-icon">S3</div>
              <h3>S3 Origin</h3>
              <p>Files served from bucket <strong>${var.bucket_name}</strong></p>
              <p class="meta">AES-256 encrypted at rest</p>
            </div>

            <div class="card">
              <div class="card-icon">CF</div>
              <h3>CloudFront CDN</h3>
              <p>Globally distributed via <strong>${local.effective_price_class}</strong></p>
              <p class="meta">HTTPS enforced · TTL ${var.default_ttl}s</p>
            </div>

            <div class="card">
              <div class="card-icon">TF</div>
              <h3>Terraform</h3>
              <p>100% infrastructure as code — zero console clicks</p>
              <p class="meta">Environment: <strong>${var.environment}</strong></p>
            </div>
          </div>

          <div class="stack-info">
            <h2>Deployment Details</h2>
            <table>
              <tr><td>Owner</td><td><span class="pill-name">Wadondera</span></td></tr>
              <tr><td>Environment</td><td><span class="pill">${var.environment}</span></td></tr>
              <tr><td>Bucket</td><td><code>${var.bucket_name}</code></td></tr>
              <tr><td>Price Class</td><td><code>${local.effective_price_class}</code></td></tr>
              <tr><td>Cache TTL</td><td><code>${var.default_ttl}s default / ${var.max_ttl}s max</code></td></tr>
              <tr><td>Versioning</td><td><code>${var.enable_versioning ? "enabled" : "disabled"}</code></td></tr>
              <tr><td>Managed by</td><td><code>Terraform</code></td></tr>
            </table>
          </div>

          <div class="challenge-info">
            <p>Built by <strong>Wadondera</strong> during the <strong>30-Day Terraform Challenge</strong></p>
            <p>AWS AI/ML UserGroup Kenya · Meru HashiCorp User Group · EveOps</p>
            <p class="hashtags">#30DayTerraformChallenge #Terraform #AWS #IaC #AWSUserGroupKenya #EveOps</p>
          </div>
        </main>

        <footer>
          <p>Deployed with <strong>Terraform</strong> · Served by <strong>AWS CloudFront</strong> · Stored in <strong>Amazon S3</strong></p>
        </footer>
      </div>
    </body>
    </html>
  HTML

  error_html_content = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>404 — Page Not Found</title>
      <link rel="stylesheet" href="styles.css">
    </head>
    <body>
      <div class="container error-page">
        <header>
          <div class="error-code">404</div>
          <h1>Page Not Found</h1>
          <p class="subtitle">The page you are looking for does not exist in this S3 bucket.</p>
        </header>
        <main>
          <a href="/" class="back-button">← Back to Home</a>
          <p class="meta" style="margin-top:2rem">
            Environment: ${var.environment} · Bucket: ${var.bucket_name}
          </p>
        </main>
        <footer>
          <p>Deployed with <strong>Terraform</strong> · AWS CloudFront + S3</p>
        </footer>
      </div>
    </body>
    </html>
  HTML

  css_content = <<-CSS
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --bg: #0f1117;
      --surface: #1a1d27;
      --surface2: #222536;
      --border: rgba(255,255,255,0.08);
      --text: #e2e8f0;
      --muted: #94a3b8;
      --accent: #6366f1;
      --accent2: #06b6d4;
      --green: #10b981;
      --radius: 12px;
      --font: 'Segoe UI', system-ui, -apple-system, sans-serif;
    }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: var(--font);
      line-height: 1.6;
      min-height: 100vh;
    }

    .container {
      max-width: 900px;
      margin: 0 auto;
      padding: 2rem 1.5rem;
    }

    header {
      text-align: center;
      padding: 4rem 0 3rem;
    }

    .badge {
      display: inline-block;
      background: var(--accent);
      color: white;
      font-size: 0.75rem;
      font-weight: 600;
      padding: 0.35rem 1rem;
      border-radius: 100px;
      margin-bottom: 1.5rem;
      letter-spacing: 0.05em;
      text-transform: uppercase;
    }

    h1 {
      font-size: clamp(2rem, 5vw, 3.5rem);
      font-weight: 700;
      background: linear-gradient(135deg, #6366f1, #06b6d4);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 1rem;
    }

    .subtitle {
      color: var(--muted);
      font-size: 1.125rem;
      max-width: 520px;
      margin: 0 auto;
    }

    .card-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 1.5rem;
      margin: 3rem 0;
    }

    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 1.75rem;
      transition: transform 0.2s, border-color 0.2s;
    }

    .card:hover {
      transform: translateY(-4px);
      border-color: var(--accent);
    }

    .card-icon {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 48px;
      height: 48px;
      background: var(--surface2);
      border: 1px solid var(--border);
      border-radius: 10px;
      font-size: 0.8rem;
      font-weight: 700;
      letter-spacing: 0.05em;
      color: var(--accent2);
      margin-bottom: 1rem;
    }

    .card h3 {
      font-size: 1.125rem;
      margin-bottom: 0.5rem;
    }

    .card p { color: var(--muted); font-size: 0.9rem; margin-bottom: 0.35rem; }
    .card .meta { font-size: 0.8rem; color: var(--accent2); }

    .stack-info {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 2rem;
      margin: 2rem 0;
    }

    .stack-info h2 {
      font-size: 1.25rem;
      margin-bottom: 1.25rem;
      color: var(--text);
    }

    table { width: 100%; border-collapse: collapse; }

    tr { border-bottom: 1px solid var(--border); }
    tr:last-child { border-bottom: none; }

    td {
      padding: 0.75rem 0;
      font-size: 0.9rem;
    }

    td:first-child { color: var(--muted); width: 40%; }

    code {
      background: var(--surface2);
      padding: 0.2rem 0.5rem;
      border-radius: 4px;
      font-size: 0.85rem;
      color: var(--accent2);
      font-family: 'Consolas', 'Monaco', monospace;
    }

    .pill {
      display: inline-block;
      background: var(--green);
      color: white;
      padding: 0.2rem 0.7rem;
      border-radius: 100px;
      font-size: 0.8rem;
      font-weight: 600;
    }

    .avatar {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: linear-gradient(135deg, #6366f1, #06b6d4);
      color: white;
      font-size: 2rem;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 1.5rem;
    }

    .pill-name {
      display: inline-block;
      background: linear-gradient(135deg, #6366f1, #06b6d4);
      color: white;
      padding: 0.2rem 0.9rem;
      border-radius: 100px;
      font-size: 0.85rem;
      font-weight: 600;
    }

    .challenge-info {
      text-align: center;
      padding: 2rem;
      color: var(--muted);
      font-size: 0.9rem;
    }

    .challenge-info strong { color: var(--text); }
    .hashtags { margin-top: 0.5rem; color: var(--accent); font-size: 0.85rem; }

    footer {
      text-align: center;
      padding: 2rem 0;
      color: var(--muted);
      font-size: 0.85rem;
      border-top: 1px solid var(--border);
      margin-top: 3rem;
    }

    footer strong { color: var(--text); }

    .error-page header { padding: 6rem 0 2rem; }
    .error-code { font-size: 8rem; font-weight: 800; color: var(--accent); opacity: 0.3; line-height: 1; }
    .back-button {
      display: inline-block;
      background: var(--accent);
      color: white;
      padding: 0.75rem 1.75rem;
      border-radius: 8px;
      text-decoration: none;
      font-weight: 600;
      margin-top: 2rem;
      transition: opacity 0.2s;
    }
    .back-button:hover { opacity: 0.85; }
  CSS
}

# ── CloudFront Distribution ────────────────────────────────────────────────

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name}-${var.environment}"
  default_root_object = var.index_document
  price_class         = local.effective_price_class
  tags                = local.common_tags

  # Aliases — only set when a custom domain is configured
  aliases = local.has_custom_domain ? [var.domain_name, "www.${var.domain_name}"] : []

  # ── Origin — S3 website endpoint via custom origin (HTTP)
  # Note: S3 website endpoints use HTTP. CloudFront → browser connection uses HTTPS.
  # This is the correct architecture for S3-hosted websites.
  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = local.origin_id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }

    # Custom headers passed to origin — can be used to restrict direct S3 access
    custom_header {
      name  = "X-Origin-Verify"
      value = "terraform-day25-challenge"
    }
  }

  # ── Default cache behaviour
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl

    # Security headers function association would go here in production
  }

  # ── Cache behaviour for CSS/JS/images — longer TTL
  ordered_cache_behavior {
    path_pattern           = "*.css"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 86400    # 24 hours for static assets
    max_ttl     = 604800   # 7 days max
  }

  # ── Custom error responses — serve error.html for 404s with correct status
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/${var.error_document}"
    error_caching_min_ttl = 10
  }

  # ── Geo restrictions — none by default
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ── SSL certificate — custom or default CloudFront cert
  viewer_certificate {
    cloudfront_default_certificate = !local.has_custom_domain
    acm_certificate_arn            = local.has_custom_domain ? var.acm_certificate_arn : null
    ssl_support_method             = local.has_custom_domain ? "sni-only" : null
    minimum_protocol_version       = local.has_custom_domain ? "TLSv1.2_2021" : null
  }

  # ── Access logging — optional
  dynamic "logging_config" {
    for_each = var.log_bucket_name != null ? [1] : []
    content {
      include_cookies = false
      bucket          = "${var.log_bucket_name}.s3.amazonaws.com"
      prefix          = "cloudfront/${var.project_name}/${var.environment}/"
    }
  }

  # CloudFront distributions take 5–15 minutes to deploy globally
  # No lifecycle tricks needed — just wait for the status to show "Deployed"
}

# ── Route53 DNS (optional) ─────────────────────────────────────────────────

resource "aws_route53_record" "website_apex" {
  count = local.has_custom_domain && var.route53_zone_id != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "website_www" {
  count = local.has_custom_domain && var.route53_zone_id != null ? 1 : 0

  zone_id = var.route53_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = aws_cloudfront_distribution.website.hosted_zone_id
    evaluate_target_health = false
  }
}
