# =============================================================================
# MODULE: security
# Description: Security groups, IAM roles, KMS keys, WAF rules
# =============================================================================

locals {
  common_tags = merge(var.common_tags, {
    Module = "security"
  })
}

# ---------------------------------------------------------------------------
# KMS Key for encryption at rest
# ---------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.cluster_name} encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowEC2EBSEncryption"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
          StringLike = {
            "kms:ViaService" = "ec2.*.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowS3Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowDynamoDB"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-kms"
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.cluster_name}"
  target_key_id = aws_kms_key.main.key_id
}

# ---------------------------------------------------------------------------
# ALB Security Group
# ---------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name_prefix = "${var.cluster_name}-alb-"
  description = "Security group for the Application Load Balancer - allows HTTP/HTTPS from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-alb-sg"
  })
}

# ---------------------------------------------------------------------------
# Web Server Security Group
# ---------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name_prefix = "${var.cluster_name}-web-"
  description = "Security group for web servers - allows traffic only from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound (for package installs, AWS API calls)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-web-sg"
  })
}

# ---------------------------------------------------------------------------
# EC2 Instance Profile & IAM Role (least-privilege)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "ec2" {
  name_prefix = "${var.cluster_name}-ec2-"
  description = "IAM role for EC2 web servers - allows SSM, CloudWatch, and S3 read"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# SSM access for secure session manager (replaces SSH)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch agent permissions
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom least-privilege policy for app-specific needs
resource "aws_iam_role_policy" "app_policy" {
  name_prefix = "${var.cluster_name}-app-"
  role        = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadAppConfig"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.config_bucket_name}",
          "arn:aws:s3:::${var.config_bucket_name}/*"
        ]
      },
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [aws_kms_key.main.arn]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "${var.cluster_name}-ec2-"
  role        = aws_iam_role.ec2.name

  tags = local.common_tags
}
