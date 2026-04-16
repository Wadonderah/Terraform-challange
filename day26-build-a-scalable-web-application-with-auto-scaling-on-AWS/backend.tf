terraform {
  backend "s3" {
    bucket         = "wadonderah"
    key            = "day26/scalable-web-app/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}
