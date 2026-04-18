terraform {
  backend "s3" {
    bucket         = "wadonderah-terraform-state"
    key            = "day27/multi-region-ha/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
