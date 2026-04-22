# =============================================================================
# locals.tf
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: Local values
# Locals are computed once and reused. They reduce repetition and centralise
# naming conventions. Unlike variables, they cannot be overridden at runtime.
# =============================================================================

locals {
  # Standardised name prefix for all resources
  name_prefix = "${var.project}-${var.environment}"

  # Common tags merged with user-supplied tags
  # merge() is idempotent - safe to run multiple times
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
      Challenge   = "30-Day-Terraform-Challenge"
      Day         = "28"
      Community   = "AWS-AI-ML-UserGroup-Kenya"
    },
    var.tags
  )

  # Availability zones derived from the region
  # Using slice() ensures we only take as many AZs as we have subnets
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    length(var.public_subnet_cidrs)
  )

  # EXAM CONCEPT: Immutable infrastructure
  # The instance name tag is stamped at creation time.
  # To "upgrade" the instance, you replace it (terraform apply -replace)
  # rather than patching it in place. This eliminates configuration drift.
  # The advantage is LESS COMPLEX upgrades, not necessarily faster ones.
  instance_name = "${local.name_prefix}-web"
}
