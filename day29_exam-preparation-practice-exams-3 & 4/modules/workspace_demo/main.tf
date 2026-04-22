# modules/workspace_demo/main.tf
# Day 29 | 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# EXAM: terraform.workspace is a built-in string.
# "default" workspace cannot be deleted.
# Each workspace has its own state file.
# CLI workspaces != Terraform Cloud workspaces.

terraform {
  required_providers {
    null = { source = "hashicorp/null" ; version = ">= 3.0, < 4.0" }
  }
}

resource "null_resource" "workspace_aware" {
  triggers = {
    # Changes per workspace: dev -> "...-dev-resource", staging -> "...-staging-resource"
    workspace_name = "${var.name}-${var.workspace_name}-resource"
  }
}