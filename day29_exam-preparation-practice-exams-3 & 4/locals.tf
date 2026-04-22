# =============================================================================
# locals.tf
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: terraform.workspace
# terraform.workspace returns the current workspace name as a STRING.
# Use it in locals to make resource naming workspace-aware.
# The default workspace name is literally "default".
# =============================================================================

locals {
  # Workspace-aware name prefix
  # EXAM NOTE: terraform.workspace is a built-in value, not a variable.
  # It cannot be set in tfvars. It is set by terraform workspace select.
  workspace    = terraform.workspace
  name_prefix  = "${var.project}-${local.workspace}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      Workspace   = local.workspace    # tags the actual TF workspace name
      ManagedBy   = "Terraform"
      Challenge   = "30-Day-Terraform-Challenge"
      Day         = "29"
      Community   = "AWS-AI-ML-UserGroup-Kenya"
    },
    var.tags
  )

  # Workspace-specific sizing — a common real-world pattern
  instance_types = {
    default = "t3.micro"
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.medium"
  }

  # Use workspace name to select instance type, fall back to default
  resolved_instance_type = lookup(
    local.instance_types,
    local.workspace,
    local.instance_types["default"]
  )
}