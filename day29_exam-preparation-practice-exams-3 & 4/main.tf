# =============================================================================
# main.tf - Root Module
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
# =============================================================================

module "random_demo" {
  source = "./modules/random_demo"
  name   = local.name_prefix
  tags   = local.common_tags
}

module "workspace_demo" {
  source         = "./modules/workspace_demo"
  name           = local.name_prefix
  workspace_name = local.workspace_name
  tags           = local.common_tags
}

module "lifecycle_demo" {
  source = "./modules/lifecycle_demo"
  name   = local.name_prefix
  tags   = local.common_tags
}