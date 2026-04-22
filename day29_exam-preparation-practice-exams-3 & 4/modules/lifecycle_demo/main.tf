# modules/lifecycle_demo/main.tf
# Day 29 | 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM: lifecycle meta-arguments
#   create_before_destroy = true  -> new resource runs BEFORE old is destroyed
#   prevent_destroy = true        -> blocks terraform destroy ONLY
#                                    does NOT block manual console deletion
#   ignore_changes = [attr]       -> ignore drift on specific attributes

terraform {
  required_providers {
    random = { source = "hashicorp/random" ; version = "~> 3.5" }
    null   = { source = "hashicorp/null"   ; version = ">= 3.0, < 4.0" }
  }
}

resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

# PATTERN 1: create_before_destroy
resource "null_resource" "cbd_demo" {
  triggers = { name = random_pet.name.id }
  lifecycle { create_before_destroy = true }
}

# PATTERN 2: prevent_destroy
# EXAM TRAP: blocks `terraform destroy` but NOT manual AWS console deletion
resource "null_resource" "protected" {
  triggers = { protected = "true" }
  lifecycle {
    prevent_destroy = true
    # To remove: set prevent_destroy = false -> terraform apply -> terraform destroy
  }
}

# PATTERN 3: ignore_changes
resource "null_resource" "drift_demo" {
  triggers = {
    name         = random_pet.name.id
    last_updated = timestamp()
  }
  lifecycle {
    ignore_changes = [triggers["last_updated"]]
  }
}