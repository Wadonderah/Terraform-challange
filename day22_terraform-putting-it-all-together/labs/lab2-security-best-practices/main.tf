# labs/lab2-security-best-practices/main.tf
# Lab 2: Security Best Practices
#
# Demonstrates the security patterns from Chapter 10:
#   1. No hardcoded secrets — credentials via AWS Secrets Manager
#   2. Encrypted S3 bucket with blocked public access
#   3. Encrypted EBS volumes
#   4. IAM role with least-privilege policy (not AdministratorAccess)
#   5. Security group with minimal open ports
#   6. VPC flow logs for audit trail
#
# Usage:
#   export TF_VAR_db_password=$(aws secretsmanager get-secret-value \
#     --secret-id lab2/db-password --query SecretString --output text)
#   terraform init && terraform apply
#   terraform destroy

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# ── Best Practice 1: Store secrets in Secrets Manager, never in code ───────
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "lab2/db-password"
  description             = "RDS master password for lab2"
  recovery_window_in_days = 0   # immediate deletion — lab only

  tags = {
    ManagedBy = "terraform"
    Lab       = "security-best-practices"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# Retrieve the secret for use in RDS — no hardcoded values
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id  = aws_secretsmanager_secret.db_password.id
  depends_on = [aws_secretsmanager_secret_version.db_password]
}

# ── Best Practice 2: S3 with encryption + blocked public access ────────────
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "lab2-secure-bucket-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = "lab2-secure-bucket"
    ManagedBy = "terraform"
    Lab       = "security-best-practices"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "secure_bucket" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ── Best Practice 3: IAM role with least-privilege policy ──────────────────
resource "aws_iam_role" "app_role" {
  name = "lab2-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    ManagedBy = "terraform"
    Lab       = "security-best-practices"
  }
}

# Only grant the permissions the application actually needs
resource "aws_iam_role_policy" "app_role_policy" {
  name = "lab2-app-policy"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_password.arn
      },
      {
        Sid    = "ReadWriteOwnBucket"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "lab2-app-instance-profile"
  role = aws_iam_role.app_role.name
}

# ── Best Practice 4: Security group — minimal open ports ───────────────────
resource "aws_security_group" "app" {
  name        = "lab2-app-sg"
  description = "Allows only port 8080 inbound — no SSH, no 0.0.0.0 admin ports"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "App traffic only"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "lab2-app-sg"
    ManagedBy = "terraform"
    Lab       = "security-best-practices"
  }
}

# ── Best Practice 5: EC2 with encrypted root volume + no public IP ─────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "secure_app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.app.name
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false   # private subnet only

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 20
  }

  metadata_options {
    http_tokens = "required"   # IMDSv2 only — prevents SSRF attacks
  }

  tags = {
    Name      = "lab2-secure-app"
    ManagedBy = "terraform"
    Lab       = "security-best-practices"
  }
}

# ── Best Practice 6: VPC flow logs for audit trail ─────────────────────────
resource "aws_flow_log" "main" {
  vpc_id          = data.aws_vpc.default.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/vpc/lab2-flow-logs"
  retention_in_days = 30

  tags = {
    ManagedBy = "terraform"
    Lab       = "security-best-practices"
  }
}

resource "aws_iam_role" "flow_log_role" {
  name = "lab2-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name = "lab2-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "*"
    }]
  })
}

# ── Data sources ───────────────────────────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_caller_identity" "current" {}

# ── Variables ──────────────────────────────────────────────────────────────
variable "db_password" {
  description = "Initial DB password — stored in Secrets Manager, never logged"
  type        = string
  sensitive   = true
}

# ── Outputs ────────────────────────────────────────────────────────────────
output "secure_bucket_name" {
  value = aws_s3_bucket.secure_bucket.bucket
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "Retrieve with: aws secretsmanager get-secret-value --secret-id lab2/db-password"
}

output "security_summary" {
  value = {
    encrypted_root_volume = true
    imdsv2_required       = true
    public_ip_disabled    = true
    flow_logs_enabled     = true
    secrets_in_code       = false
  }
}
