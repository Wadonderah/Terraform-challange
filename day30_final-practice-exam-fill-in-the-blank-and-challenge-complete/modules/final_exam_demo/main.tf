# modules/final_exam_demo/main.tf
# Day 30 | 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# Demonstrates all key concepts from the fill-in-the-blank and readiness check.
# Run: terraform state list, terraform state show, terraform graph after apply.

terraform {
  required_providers {
    random = { source = "hashicorp/random" ; version = "~> 3.5" }
    null   = { source = "hashicorp/null"   ; version = ">= 3.0, < 4.0" }
  }
}

resource "random_id" "exam" {
  byte_length = 4
  keepers     = { name = var.name }
}

# FILL-IN-THE-BLANK Q2: prevent_destroy
resource "null_resource" "protected_resource" {
  triggers = { challenge = "30-day-complete" }
  lifecycle {
    prevent_destroy = true
    # Blocks terraform destroy. Does NOT block console deletion.
  }
}

# FILL-IN-THE-BLANK Q6: terraform state rm candidate
# After apply: terraform state rm module.final_exam_demo.null_resource.practice
# The null_resource is removed from state but "conceptually survives"
resource "null_resource" "practice" {
  triggers = { id = random_id.exam.hex }
}

# READINESS CHECK Q4: depends_on
# Explicit dependency where no resource reference exists
resource "null_resource" "dependent" {
  depends_on = [null_resource.protected_resource]
  triggers   = { always = timestamp() }
}