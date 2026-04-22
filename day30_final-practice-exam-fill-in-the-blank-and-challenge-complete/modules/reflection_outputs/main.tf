# modules/reflection_outputs/main.tf
# Day 30 | 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps

terraform {
  required_providers {
    null = { source = "hashicorp/null" ; version = ">= 3.0, < 4.0" }
  }
}

resource "null_resource" "challenge_complete" {
  triggers = {
    day         = "30"
    status      = "COMPLETE"
    environment = var.environment
    workspace   = var.workspace
    community   = "AWS-AI-ML-UserGroup-Kenya-Meru-HashiCorp-EveOps"
  }
}