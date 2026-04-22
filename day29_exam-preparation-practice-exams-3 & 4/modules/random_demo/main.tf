# modules/random_demo/main.tf
# Day 29 | 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM: Simple resource for practising all state commands after apply.
# Run: bash state_commands.sh
#
# State command reminder:
#   terraform state list  -> lists addresses
#   terraform state show  -> shows attributes from state
#   terraform state rm    -> removes from state ONLY (infra survives)
#   terraform state mv    -> renames address in state (infra unchanged)
#   terraform import      -> adopts existing resource (does NOT generate .tf)

terraform {
  required_providers {
    random = { source = "hashicorp/random" ; version = "~> 3.5" }
    null   = { source = "hashicorp/null"   ; version = ">= 3.0, < 4.0" }
  }
}

resource "random_id" "this" {
  byte_length = 4
  keepers = { name = var.name }
}

resource "null_resource" "state_practice" {
  triggers = { id = random_id.this.hex }
}