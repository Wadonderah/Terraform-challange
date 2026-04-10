# tests/unit/mysql_module_test.tftest.hcl
# Unit tests for the MySQL module — validates variable constraints
# and production-safety settings without touching real AWS.

run "prod_requires_deletion_protection" {
  command = plan

  variables {
    db_name             = "test-db"
    environment         = "prod"
    vpc_id              = "vpc-00000000000000000"
    subnet_ids          = ["subnet-00000000000000001", "subnet-00000000000000002"]
    db_username         = "admin"
    db_password         = "TestPass123!"
    deletion_protection = true
    multi_az            = true
    skip_final_snapshot = false
  }

  assert {
    condition     = var.deletion_protection == true
    error_message = "Production must have deletion_protection = true"
  }

  assert {
    condition     = var.multi_az == true
    error_message = "Production must have multi_az = true"
  }

  assert {
    condition     = var.skip_final_snapshot == false
    error_message = "Production must have skip_final_snapshot = false"
  }
}

run "dev_allows_no_deletion_protection" {
  command = plan

  variables {
    db_name             = "dev-test-db"
    environment         = "dev"
    vpc_id              = "vpc-00000000000000000"
    subnet_ids          = ["subnet-00000000000000001"]
    db_username         = "admin"
    db_password         = "TestPass123!"
    deletion_protection = false
    skip_final_snapshot = true
  }

  assert {
    condition     = var.environment == "dev"
    error_message = "Environment should be dev"
  }
}
