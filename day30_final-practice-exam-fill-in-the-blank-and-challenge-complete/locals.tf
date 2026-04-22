# =============================================================================
# locals.tf
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# FILL-IN-THE-BLANK ANSWER 3:
# terraform.workspace returns the current workspace name as a string.
# It is a built-in expression — not a variable, not set in tfvars.
# It is controlled by: terraform workspace select <name>
# =============================================================================

locals {
  workspace   = terraform.workspace  # FILL-IN-THE-BLANK Q3 answer
  name_prefix = "${var.project}-${local.workspace}"

  common_tags = merge({
    Project   = var.project
    Workspace = terraform.workspace
    ManagedBy = "Terraform"
    Challenge = "30-Day-Terraform-Challenge"
    Day       = "30"
    Community = "AWS-AI-ML-UserGroup-Kenya"
  }, var.tags)

  # READINESS CHECK ANSWER 5 (locals vs variables in practice):
  # This derived value cannot be set from outside — it is internal logic.
  # If it needed to be configurable, it would be a variable instead.
  is_production = local.workspace == "prod" || var.environment == "prod"
}