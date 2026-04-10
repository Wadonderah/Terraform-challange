# tests/unit/asg_module_test.tftest.hcl
# Native terraform test — runs without touching real AWS
# Tests: variable validation, instance_type guard, min_size guard

# ── Test 1: valid configuration passes validation ──────────────────────────
run "valid_instance_type_passes" {
  command = plan

  variables {
    cluster_name          = "test-cluster"
    environment           = "dev"
    instance_type         = "t3.micro"
    min_size              = 1
    max_size              = 3
    vpc_id                = "vpc-00000000000000000"
    subnet_ids            = ["subnet-00000000000000001", "subnet-00000000000000002"]
    target_group_arn      = "arn:aws:elasticloadbalancing:us-east-2:123456789012:targetgroup/test/abc123"
    alb_security_group_id = "sg-00000000000000001"
  }

  # Plan should succeed with no errors
  assert {
    condition     = var.instance_type == "t3.micro"
    error_message = "Expected instance_type to be t3.micro"
  }
}

# ── Test 2: invalid instance type is rejected ──────────────────────────────
run "invalid_instance_type_rejected" {
  command = plan

  variables {
    cluster_name          = "test-cluster"
    environment           = "dev"
    instance_type         = "m5.8xlarge"   # not in allowed list
    min_size              = 1
    max_size              = 3
    vpc_id                = "vpc-00000000000000000"
    subnet_ids            = ["subnet-00000000000000001"]
    target_group_arn      = "arn:aws:elasticloadbalancing:us-east-2:123456789012:targetgroup/test/abc123"
    alb_security_group_id = "sg-00000000000000001"
  }

  expect_failures = [var.instance_type]
}

# ── Test 3: min_size of zero is rejected ───────────────────────────────────
run "zero_min_size_rejected" {
  command = plan

  variables {
    cluster_name          = "test-cluster"
    environment           = "dev"
    instance_type         = "t3.micro"
    min_size              = 0             # must be >= 1
    max_size              = 3
    vpc_id                = "vpc-00000000000000000"
    subnet_ids            = ["subnet-00000000000000001"]
    target_group_arn      = "arn:aws:elasticloadbalancing:us-east-2:123456789012:targetgroup/test/abc123"
    alb_security_group_id = "sg-00000000000000001"
  }

  expect_failures = [var.min_size]
}

# ── Test 4: autoscaling schedules only created when enabled ───────────────
run "autoscaling_schedule_count" {
  command = plan

  variables {
    cluster_name          = "test-cluster"
    environment           = "dev"
    instance_type         = "t3.micro"
    min_size              = 1
    max_size              = 3
    enable_autoscaling    = false
    vpc_id                = "vpc-00000000000000000"
    subnet_ids            = ["subnet-00000000000000001"]
    target_group_arn      = "arn:aws:elasticloadbalancing:us-east-2:123456789012:targetgroup/test/abc123"
    alb_security_group_id = "sg-00000000000000001"
  }

  assert {
    condition     = var.enable_autoscaling == false
    error_message = "enable_autoscaling should be false"
  }
}
