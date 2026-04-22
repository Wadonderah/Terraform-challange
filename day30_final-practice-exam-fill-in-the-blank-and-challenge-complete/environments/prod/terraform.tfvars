# environments/prod/terraform.tfvars
# Day 30 | 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps

environment  = "prod"
aws_region   = "us-east-1"
project      = "day30-challenge-complete"
bucket_names = ["logs", "backups", "artifacts", "audit"]
tags = { Team = "platform", Day = "30", Critical = "true" }