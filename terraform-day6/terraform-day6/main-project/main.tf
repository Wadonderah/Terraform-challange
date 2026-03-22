  # ─── REMOTE BACKEND CONFIG ───────────────────────────────────────────────
  # NOTE: Run backend-bootstrap/main.tf FIRST before adding this block.
  # After the S3 bucket and DynamoDB table exist, run: terraform init
  # Terraform will detect the new backend and migrate your local state to S3.


terraform {
  backend "s3" {
    bucket = "wadondera-terraform-state-556684850027"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# Deploy a simple S3 bucket to confirm state is working correctly

resource "aws_s3_bucket" "example" {
  bucket = "wadondera-example-bucket-556684850027"

  tags = {
    Name      = "terraform-day6-example-bucket"
    Challenge = "challenge-6"
  }
}
