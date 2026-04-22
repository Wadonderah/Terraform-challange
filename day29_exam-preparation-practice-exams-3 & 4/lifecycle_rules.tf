# =============================================================================
# lifecycle_rules.tf
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM CONCEPT: lifecycle meta-arguments
#
# Persistent wrong answer across exams: prevent_destroy behaviour
#
# WRONG: prevent_destroy = true prevents ANYONE from deleting the resource.
# RIGHT: prevent_destroy = true prevents terraform destroy from removing it.
#        Deleting directly in the AWS console bypasses Terraform entirely.
#        prevent_destroy only guards against accidental terraform destroy.
# =============================================================================

provider "aws" {
  region = var.aws_region
  default_tags { tags = local.common_tags }
}

# -----------------------------------------------------------------------------
# LIFECYCLE PATTERN 1: create_before_destroy
#
# Default Terraform behaviour: destroy old resource, THEN create new one.
# With create_before_destroy = true: create new resource FIRST, then destroy old.
#
# Use when: replacing a resource that must have zero downtime
#           (load balancer target groups, SSL certificates, etc.)
#
# EXAM NOTE: Some resources require create_before_destroy because their
# names must be unique — you can't have two with the same name simultaneously.
# For those, use a random suffix (see random_pet below).
# -----------------------------------------------------------------------------
resource "random_pet" "server_name" {
  length = 2
  # random_pet generates a new name on every apply unless kept in state.
  # EXAM: terraform state rm random_pet.server_name would cause a new name
  # on next apply, potentially triggering replacement of dependent resources.

  lifecycle {
    # Keep the same random name even if we want to regenerate
    # (prevents downstream resource churn)
    ignore_changes = [length]
  }
}

resource "null_resource" "create_before_destroy_demo" {
  triggers = {
    name = random_pet.server_name.id
  }

  lifecycle {
    # EXAM: create_before_destroy = true
    # New resource runs its provisioner BEFORE the old one is destroyed.
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# LIFECYCLE PATTERN 2: prevent_destroy
#
# EXAM TRAP (appeared in both Exam 3 and Exam 4):
# prevent_destroy = true means:
#   terraform destroy -> ERROR, plan rejected
#   AWS console delete -> SUCCEEDS (Terraform has no visibility)
#   terraform apply -destroy -> ERROR, plan rejected
#
# prevent_destroy does NOT:
#   - Encrypt or secure the resource
#   - Prevent manual deletion via CLI or console
#   - Apply to resources created outside Terraform
# -----------------------------------------------------------------------------
resource "null_resource" "prevent_destroy_demo" {
  triggers = {
    always_run = timestamp()
  }

  lifecycle {
    prevent_destroy = true
    # To destroy this resource you must first:
    # 1. Remove or set prevent_destroy = false in the config
    # 2. Run terraform apply to update the lifecycle
    # 3. Then run terraform destroy
  }
}

# -----------------------------------------------------------------------------
# LIFECYCLE PATTERN 3: ignore_changes
#
# Use when: external systems modify resource attributes (auto-scaling AMIs,
# manually tagged resources, etc.) and you don't want Terraform to revert them.
#
# EXAM: ignore_changes accepts a LIST of attribute names.
# Special value: ignore_changes = all  -> ignore ALL attribute changes.
# This effectively makes the resource unmanaged after initial creation.
# -----------------------------------------------------------------------------
resource "null_resource" "ignore_changes_demo" {
  triggers = {
    # This trigger will be ignored — Terraform won't detect timestamp drift
    last_updated = timestamp()
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to specific trigger keys
      triggers["last_updated"],
    ]
  }
}

# -----------------------------------------------------------------------------
# LIFECYCLE PATTERN 4: replace_triggered_by (Terraform >= 1.2)
#
# Forces replacement of this resource when the referenced resource changes.
# Useful for resources that don't automatically detect upstream changes.
# -----------------------------------------------------------------------------
resource "null_resource" "replace_triggered_by_demo" {
  lifecycle {
    replace_triggered_by = [
      null_resource.prevent_destroy_demo
      # When prevent_destroy_demo is replaced, this resource is also replaced.
    ]
  }
}

# -----------------------------------------------------------------------------
# LIFECYCLE SUMMARY OUTPUT
# Query: terraform output lifecycle_concepts
# -----------------------------------------------------------------------------
output "lifecycle_concepts" {
  description = "Lifecycle meta-argument summary for exam review."
  value = {
    create_before_destroy = {
      what_it_does    = "Creates replacement resource before destroying original"
      exam_use_case   = "Zero-downtime replacements, unique-name resources"
      default         = "false (destroy first, then create)"
    }
    prevent_destroy = {
      what_it_does    = "Blocks terraform destroy from removing the resource"
      exam_trap       = "Does NOT prevent manual deletion via console or CLI"
      to_override     = "Set prevent_destroy = false then terraform apply, then destroy"
    }
    ignore_changes = {
      what_it_does    = "Tells Terraform to ignore drift on listed attributes"
      exam_use_case   = "Resources modified by external systems (autoscaling, manual ops)"
      special_value   = "ignore_changes = all ignores every attribute"
    }
    replace_triggered_by = {
      what_it_does    = "Forces replacement when referenced resource changes"
      minimum_version = "Terraform >= 1.2"
    }
  }
}