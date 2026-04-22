# =============================================================================
# modules/state_demo/main.tf
# Day 28: Terraform Associate Exam Prep
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# PURPOSE: Practice state management commands that appear on the exam.
#
# After terraform apply, run these commands to learn by doing:
#
# 1. List all resources in state
#    terraform state list
#
# 2. Inspect a resource in detail
#    terraform state show module.state_demo.aws_s3_bucket.demo
#
# 3. Rename a resource in state (does NOT change real infrastructure)
#    terraform state mv module.state_demo.aws_s3_bucket.demo module.state_demo.aws_s3_bucket.renamed
#    # Bucket still exists in AWS with the same name. Only state address changed.
#
# 4. Remove resource from state WITHOUT destroying it
#    terraform state rm module.state_demo.aws_s3_bucket.renamed
#    # EXAM TRAP: This does NOT delete the bucket. It is now unmanaged by Terraform.
#    # Verify: aws s3 ls | grep day28
#
# 5. Import the orphaned resource back into state
#    terraform import module.state_demo.aws_s3_bucket.demo <bucket-name>
#    # Use the bucket_name output value as the import ID.
#
# 6. Compare: terraform destroy actually deletes the resource
#    terraform destroy -target=module.state_demo.aws_s3_bucket.demo
#    # Bucket is GONE from both state AND AWS.
#
# KEY DISTINCTION:
#   terraform state rm -> removes from state only, real resource survives
#   terraform destroy  -> removes from state AND deletes real resource
# =============================================================================

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "demo" {
  # S3 bucket names must be globally unique - suffix ensures this
  bucket = "${var.name}-state-demo-${random_string.suffix.result}"

  tags = merge(var.tags, {
    Name    = "${var.name}-state-demo"
    Purpose = "Day28-State-Management-Practice"
    # EXAM NOTE: Tags are stored in terraform.tfstate
    # Even sensitive tag values are plaintext in the state file.
  })
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "demo" {
  bucket = aws_s3_bucket.demo.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table for state locking - used when backend is S3
# EXAM CONCEPT: State locking prevents concurrent modifications
resource "aws_dynamodb_table" "locks" {
  name         = "${var.name}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, {
    Name    = "${var.name}-tf-locks"
    Purpose = "Terraform-State-Locking"
  })
}