
terraform {
  backend "s3" {
    bucket         = "wadondera-terraform-state-556684850027"
    key            = "environments/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
