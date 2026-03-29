# =============================================================================
# providers.tf — AWS Provider Configuration
# =============================================================================
# AWS credentials are NEVER placed here.
# The provider reads from environment variables automatically:
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#   AWS_DEFAULT_REGION
# =============================================================================

provider "aws" {
  region = var.aws_region

  # Only enforce account restriction when aws_account_id is explicitly set
  allowed_account_ids = var.aws_account_id != "" ? [var.aws_account_id] : []

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "day13-secrets-demo"
    }
  }
}
