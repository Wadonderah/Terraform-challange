# =============================================================================
# main.tf - Root Module
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
# =============================================================================

provider "aws" {
  region = var.aws_region
  default_tags { tags = local.common_tags }
}

# FILL-IN-THE-BLANK ANSWER 5: for_each with toset()
# for_each requires a map or SET — not a plain list.
# toset() converts the list to a set, removing duplicates and providing string keys.
resource "aws_s3_bucket" "challenge_buckets" {
  for_each = toset(var.bucket_names)

  bucket = "${local.name_prefix}-${each.key}"
  # Creates: day30-challenge-complete-<workspace>-logs
  #          day30-challenge-complete-<workspace>-backups
  #          day30-challenge-complete-<workspace>-artifacts
  # State addresses: aws_s3_bucket.challenge_buckets["logs"] etc.
}

resource "aws_s3_bucket_versioning" "challenge_buckets" {
  for_each = aws_s3_bucket.challenge_buckets

  bucket = each.value.id
  versioning_configuration { status = "Enabled" }
}

# READINESS CHECK ANSWER 4: depends_on example
# IAM policy propagation delay — dependency not expressible through references
resource "null_resource" "depends_on_demo" {
  depends_on = [aws_s3_bucket.challenge_buckets]
  # EXAM: depends_on creates explicit ordering when implicit references
  # are insufficient. Use sparingly — overuse slows plans.
  triggers = { always_run = timestamp() }
}

# Module calls
module "final_exam_demo" {
  source = "./modules/final_exam_demo"
  name   = local.name_prefix
  tags   = local.common_tags
}

module "reflection_outputs" {
  source      = "./modules/reflection_outputs"
  environment = var.environment
  workspace   = local.workspace
  tags        = local.common_tags
}