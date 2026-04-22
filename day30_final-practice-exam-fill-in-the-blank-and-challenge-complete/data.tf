# =============================================================================
# data.tf
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# FILL-IN-THE-BLANK ANSWER 8:
# data block reads EXISTING infrastructure (read-only, no changes)
# resource block manages infrastructure (create, update, destroy)
# =============================================================================

# FILL-IN-THE-BLANK ANSWER 8 demonstrated:
# This data source reads existing infrastructure — Terraform does not own it
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" { state = "available" }