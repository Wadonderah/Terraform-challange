# =============================================================================
# Day 27 — 3-Tier Multi-Region HA: Production Environment Root
#
# Data flow summary:
#   module.vpc_primary        → vpc_id, public/private subnet IDs → module.alb_primary, module.asg_primary, module.rds_primary
#   module.alb_primary        → target_group_arn                  → module.asg_primary
#   module.alb_primary        → alb_security_group_id             → module.asg_primary
#   module.asg_primary        → instance_security_group_id        → module.rds_primary
#   module.rds_primary        → db_instance_arn                   → module.rds_replica (cross-region)
#   module.alb_primary/sec    → alb_dns_name, alb_zone_id         → module.route53
#
# All providers passed explicitly — no implicit default provider usage.
# =============================================================================

# ── PRIMARY REGION: us-east-1 ─────────────────────────────────────────────────

module "vpc_primary" {
  source    = "../../modules/vpc"
  providers = { aws = aws.primary }

  vpc_cidr             = var.primary_vpc_cidr
  public_subnet_cidrs  = var.primary_public_subnet_cidrs
  private_subnet_cidrs = var.primary_private_subnet_cidrs
  availability_zones   = var.primary_availability_zones
  environment          = var.environment
  region               = "us-east-1"

  tags = {
    Owner = "Wadonderah"
    Day   = "27"
  }
}

module "alb_primary" {
  source    = "../../modules/alb"
  providers = { aws = aws.primary }

  name        = var.app_name
  vpc_id      = module.vpc_primary.vpc_id
  subnet_ids  = module.vpc_primary.public_subnet_ids   # ALB lives in public subnets
  environment = var.environment
  region      = "us-east-1"

  tags = {
    Owner = "Wadonderah"
    Day   = "27"
  }
}

module "asg_primary" {
  source    = "../../modules/asg"
  providers = { aws = aws.primary }

  launch_template_ami   = var.primary_ami_id
  instance_type         = var.instance_type
  vpc_id                = module.vpc_primary.vpc_id
  subnet_ids            = module.vpc_primary.private_subnet_ids  # instances in private subnets
  target_group_arns     = [module.alb_primary.target_group_arn]  # wired from alb_primary
  alb_security_group_id = module.alb_primary.alb_security_group_id # allow traffic from ALB only
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  environment           = var.environment
  region                = "us-east-1"

  tags = {
    Owner = "Wadonderah"
    Day   = "27"
  }
}

module "rds_primary" {
  source    = "../../modules/rds"
  providers = { aws = aws.primary }

  identifier            = "${var.app_name}-db-primary"
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  instance_class        = var.db_instance_class
  subnet_ids            = module.vpc_primary.private_subnet_ids
  vpc_id                = module.vpc_primary.vpc_id
  app_security_group_id = module.asg_primary.instance_security_group_id # RDS allows only app tier
  multi_az              = true   # Multi-AZ protects against single-AZ failures
  is_replica            = false
  environment           = var.environment
  region                = "us-east-1"

  tags = {
    Owner = "Wadonderah"
    Day   = "27"
  }
}

# ── SECONDARY REGION: us-west-2 ───────────────────────────────────────────────

module "vpc_secondary" {
  source    = "../../modules/vpc"
  providers = { aws = aws.secondary }

  vpc_cidr             = var.secondary_vpc_cidr
  public_subnet_cidrs  = var.secondary_public_subnet_cidrs
  private_subnet_cidrs = var.secondary_private_subnet_cidrs
  availability_zones   = var.secondary_availability_zones
  environment          = var.environment
  region               = "us-west-2"

  tags = {
    Owner = "Wadonderah"
    Day   = "27"
  }
}

module "alb_secondary" {
  source    = "../../modules/alb"
  providers = { aws = aws.secondary }

  name        = var.app_name
  vpc_id      = module.vpc_secondary.vpc_id
  subnet_ids  = module.vpc_secondary.public_subnet_ids
  environment = var.environment
  region      = "us-west-2"

  tags = {
    Owner = "Wadonderah"
    Day   = "27"
  }
}

module "asg_secondary" {
  source    = "../../modules/asg"
  providers = { aws = aws.secondary }

  launch_template_ami   = var.secondary_ami_id
  instance_type         = var.instance_type
  vpc_id                = module.vpc_secondary.vpc_id
  subnet_ids            = module.vpc_secondary.private_subnet_ids
  target_group_arns     = [module.alb_secondary.target_group_arn]
  alb_security_group_id = module.alb_secondary.alb_security_group_id
  min_size              = var.min_size
  max_size              = var.max_size
  desired_capacity      = var.desired_capacity
  environment           = var.environment
  region                = "us-west-2"

  tags = {
    Owner = "Wadonderah"
    Day   = "27"
  }
}

module "rds_replica" {
  source    = "../../modules/rds"
  providers = { aws = aws.secondary }

  identifier            = "${var.app_name}-db-replica"
  is_replica            = true
  # KEY CROSS-REGION WIRE: primary RDS ARN flows directly into replica's source
  replicate_source_db   = module.rds_primary.db_instance_arn
  instance_class        = var.db_instance_class
  subnet_ids            = module.vpc_secondary.private_subnet_ids
  vpc_id                = module.vpc_secondary.vpc_id
  app_security_group_id = module.asg_secondary.instance_security_group_id
  multi_az              = false  # replica is single-AZ; promote to Multi-AZ on failover
  environment           = var.environment
  region                = "us-west-2"

  # Replica ignores these but they are declared in the module schema
  db_name     = ""
  db_username = ""
  db_password = ""

  tags = {
    Owner = "Wadonderah"
    Day   = "27"
  }
}

# ── ROUTE53 FAILOVER DNS ──────────────────────────────────────────────────────
# Route53 is a global service — uses the default provider (us-east-1)
# COMMENTED OUT: Uncomment and configure when you have a Route53 hosted zone

# module "route53" {
#   source = "../../modules/route53"
#
#   hosted_zone_id         = var.hosted_zone_id
#   domain_name            = var.domain_name
#
#   # Primary region ALB wired from module outputs
#   primary_alb_dns_name   = module.alb_primary.alb_dns_name
#   primary_alb_zone_id    = module.alb_primary.alb_zone_id
#
#   # Secondary region ALB wired from module outputs
#   secondary_alb_dns_name = module.alb_secondary.alb_dns_name
#   secondary_alb_zone_id  = module.alb_secondary.alb_zone_id
#
#   primary_region         = "us-east-1"
#   secondary_region       = "us-west-2"
#
#   health_check_path               = "/health"
#   health_check_interval           = 30
#   health_check_failure_threshold  = 3
#
#   tags = {
#     Owner = "Wadonderah"
#     Day   = "27"
#   }
# }

# ── BONUS: S3 Cross-Region Replication for static assets ─────────────────────

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "primary_assets" {
  provider = aws.primary
  bucket   = "wadonderah-assets-primary-${random_id.suffix.hex}"

  tags = {
    Name        = "wadonderah-assets-primary"
    Environment = var.environment
    Owner       = "Wadonderah"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "secondary_assets" {
  provider = aws.secondary
  bucket   = "wadonderah-assets-secondary-${random_id.suffix.hex}"

  tags = {
    Name        = "wadonderah-assets-secondary"
    Environment = var.environment
    Owner       = "Wadonderah"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access on both buckets
resource "aws_s3_bucket_public_access_block" "primary" {
  provider                = aws.primary
  bucket                  = aws_s3_bucket.primary_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "secondary" {
  provider                = aws.secondary
  bucket                  = aws_s3_bucket.secondary_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role that S3 assumes to perform replication
resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "s3-replication-role-${var.environment}-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Owner     = "Wadonderah"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy" "replication" {
  provider = aws.primary
  name     = "s3-replication-policy"
  role     = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.primary_assets.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.primary_assets.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.secondary_assets.arn}/*"
      }
    ]
  })
}

# Replication configuration — primary → secondary
resource "aws_s3_bucket_replication_configuration" "assets" {
  provider = aws.primary
  role     = aws_iam_role.replication.arn
  bucket   = aws_s3_bucket.primary_assets.id

  rule {
    id     = "replicate-all-objects"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.secondary_assets.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.secondary
  ]
}
