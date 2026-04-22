# environments/dev/terraform.tfvars
# Day 30 | 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps

environment  = "dev"
aws_region   = "us-east-1"
project      = "day30-challenge-complete"
bucket_names = ["logs", "backups", "artifacts"]
tags = { Team = "platform", Day = "30" }