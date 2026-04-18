# =============================================================================
# Day 27 — Production terraform.tfvars
# Owner: Wadonderah
#
# BEFORE RUNNING terraform apply:
#   1. Replace hosted_zone_id with your real Route53 hosted zone ID
#      → AWS Console → Route53 → Hosted Zones → copy the Zone ID
#   2. Replace domain_name with your real domain (e.g. app.yourdomain.com)
#   3. Change db_password to a strong password (min 8 chars, no @ / " ')
#   4. AMI IDs below are Amazon Linux 2023 — verify they are current:
#      Primary (us-east-1):
#        aws ec2 describe-images --owners amazon \
#          --filters "Name=name,Values=al2023-ami-*-x86_64" \
#          --region us-east-1 \
#          --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text
#      Secondary (us-west-2): same command with --region us-west-2
#   5. Ensure your S3 bucket "Wadonderah" exists and the DynamoDB table
#      "terraform-state-locks" exists in us-east-1
# =============================================================================

app_name    = "wadonderah-day27"
environment = "prod"

# ── EC2 ───────────────────────────────────────────────────────────────────────
# Amazon Linux 2023 — STANDARD AMIs (NOT ECS-optimized) - updated 2026-04-17
primary_ami_id   = "ami-0c1e21d82fe9c9336"   # us-east-1 - al2023-ami-2023.11.20260413.0
secondary_ami_id = "ami-0250adf05ecc45684"   # us-west-2 - al2023-ami-2023.11.20260413.0
instance_type    = "t3.micro"
min_size         = 1
max_size         = 4
desired_capacity = 2

# ── Primary VPC: us-east-1 ────────────────────────────────────────────────────
primary_vpc_cidr             = "10.0.0.0/16"
primary_public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
primary_private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
primary_availability_zones   = ["us-east-1a", "us-east-1b"]

# ── Secondary VPC: us-west-2 ─────────────────────────────────────────────────
secondary_vpc_cidr             = "10.1.0.0/16"
secondary_public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
secondary_private_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
secondary_availability_zones   = ["us-west-2a", "us-west-2b"]

# ── RDS ───────────────────────────────────────────────────────────────────────
db_name          = "wadonderahdb"
db_username      = "wadmin"
db_password      = "Wadonderah2024!"   # ← Change this before apply
db_instance_class = "db.t3.micro"

# ── Route53 ───────────────────────────────────────────────────────────────────
# Replace both values below with your real Route53 zone
hosted_zone_id = "ZXXXXXXXXXXXXX"           # e.g. Z1PA6795UKMFR9
domain_name    = "app.wadonderah.example.com"  # e.g. app.yourdomain.com
