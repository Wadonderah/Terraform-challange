# tests/unit/vpc_module_test.tftest.hcl
# Tests VPC module variable defaults and structure

run "vpc_default_cidr" {
  command = plan

  variables {
    name        = "test-vpc"
    environment = "dev"
  }

  assert {
    condition     = var.vpc_cidr == "10.0.0.0/16"
    error_message = "Default VPC CIDR should be 10.0.0.0/16"
  }
}

run "vpc_subnet_count_matches_az_count" {
  command = plan

  variables {
    name        = "test-vpc"
    environment = "dev"
    public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
    availability_zones   = ["us-east-2a", "us-east-2b"]
  }

  assert {
    condition     = length(var.public_subnet_cidrs) == length(var.availability_zones)
    error_message = "Public subnet count must match AZ count"
  }

  assert {
    condition     = length(var.private_subnet_cidrs) == length(var.availability_zones)
    error_message = "Private subnet count must match AZ count"
  }
}
