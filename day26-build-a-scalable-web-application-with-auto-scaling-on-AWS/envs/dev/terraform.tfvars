# ─────────────────────────────────────────────────────────────────────────────
# Dev environment variable values
#
# BEFORE RUNNING:
#   1. Replace vpc_id with your actual VPC ID
#   2. Replace public_subnet_ids with real public subnet IDs (≥2 AZs)
#   3. Replace private_subnet_ids with real private subnet IDs (≥2 AZs)
#   4. Verify ami_id is current for your region (value below = us-east-1)
#      To find the latest AL2023 AMI in your region:
#        aws ec2 describe-images \
#          --owners amazon \
#          --filters "Name=name,Values=al2023-ami-*-x86_64" \
#          --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
#          --output text
# ─────────────────────────────────────────────────────────────────────────────

app_name    = "web-challenge-day26"
environment = "dev"

# Amazon Linux 2023 — us-east-1 (latest as of 2026-04-14)
ami_id        = "ami-0102a36b3e9d5e4df"
instance_type = "t3.micro"

# ── Networking — Default VPC (172.31.0.0/16) ─────────────────────────────────
# CRITICAL: ALB and EC2 instances MUST be in the SAME Availability Zones
# ALB subnets (public): us-east-1a, us-east-1f
# ASG subnets (private): MUST match ALB AZs → us-east-1a, us-east-1f
vpc_id             = "vpc-04214292df294b431"
public_subnet_ids  = ["subnet-09b304f5e1e3330fd", "subnet-0a006c45693874764"]  # us-east-1a, us-east-1f
private_subnet_ids = ["subnet-09b304f5e1e3330fd", "subnet-0a006c45693874764"]  # us-east-1a, us-east-1f (same as ALB)

# ── Auto Scaling parameters ──────────────────────────────────────────────────
min_size         = 1
max_size         = 4
desired_capacity = 2

# ── CloudWatch scaling thresholds ────────────────────────────────────────────
cpu_scale_out_threshold = 70
cpu_scale_in_threshold  = 30
