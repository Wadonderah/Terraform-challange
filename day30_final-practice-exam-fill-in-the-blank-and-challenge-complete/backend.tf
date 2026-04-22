# =============================================================================
# backend.tf
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# FILL-IN-THE-BLANK ANSWER 4:
# The S3 backend requires encrypt = true for server-side encryption.
# This is NOT the same as sensitive = true on output values.
#   sensitive = true  -> suppresses CLI display only, state is plaintext
#   encrypt = true    -> encrypts the state file at rest in S3
#
# READINESS CHECK ANSWER 3:
# Never commit terraform.tfstate to version control because:
#   1. State contains sensitive values in plaintext (passwords, keys, tokens)
#      even when sensitive = true is set on outputs
#   2. Multiple team members pushing different state files causes corruption
#   3. State files pollute git history — use remote backend with locking instead
# =============================================================================

terraform {
  cloud {
    organization = "your-org-name"
    workspaces {
      name = "day30-challenge-complete"
    }
  }

  # S3 backend alternative — uncomment to use
  # backend "s3" {
  #   bucket         = "my-tf-state-day30"
  #   key            = "day30/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true                    # FILL-IN-THE-BLANK Q4 answer
  #   kms_key_id     = "arn:aws:kms:..."       # optional: customer-managed key
  #   dynamodb_table = "terraform-state-locks" # state locking table
  # }
}