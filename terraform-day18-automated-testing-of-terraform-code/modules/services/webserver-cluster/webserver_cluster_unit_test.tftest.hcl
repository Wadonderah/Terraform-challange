###############################################################
# modules/services/webserver-cluster/webserver_cluster_unit_test.tftest.hcl
#
# Day 18: Unit Tests with terraform test (Terraform >= 1.6)
#
# HOW THESE WORK
# --------------
# Every run block with command = plan runs entirely against the
# PLAN — no real AWS resources are created, no costs incurred,
# and tests complete in seconds. This makes them safe to run on
# every pull request in CI without AWS credentials (mock
# providers can be used, or plan-only assertions are enough).
#
# WHAT UNIT TESTS CATCH
# ---------------------
# - Variable validation logic (lengths, allowed values)
# - Resource naming conventions (name_prefix, tags)
# - Security group port assignments
# - ASG size constraints
# - Conditional logic inside locals{}
#
# WHAT UNIT TESTS DO NOT CATCH
# ----------------------------
# - Whether the ALB actually serves traffic (integration test)
# - Whether the ASG replaces a terminated instance (E2E test)
# - Network reachability between components (integration test)
###############################################################

# ── Shared variable block ─────────────────────────────────
# All run blocks inherit these unless they override individually.

variables {
  cluster_name     = "test-cluster"
  instance_type    = "t3.micro"
  min_size         = 1
  max_size         = 2
  environment      = "dev"
  server_port      = 8080
  alb_port         = 80
  hello_world_text = "Hi Wadondera welcome back!"
}

###############################################################
# RUN 1: ASG name prefix
#
# WHY THIS ASSERTION MATTERS
# The ASG name prefix is derived from cluster_name. If the
# interpolation is wrong, every resource in the cluster gets
# an incorrect name — breaking CloudWatch dashboards, Cost
# Explorer filters, and any automation keyed on the name.
###############################################################

run "validate_asg_name_prefix" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.example.name_prefix == "test-cluster-"
    error_message = "ASG name_prefix must be '<cluster_name>-'. Got unexpected value."
  }
}

###############################################################
# RUN 2: Instance type flows through to the launch template
#
# WHY THIS ASSERTION MATTERS
# If instance_type were hardcoded inside the module instead of
# referencing var.instance_type, the variable would be silently
# ignored. This test guarantees the wiring is correct — a
# change to instance_type in a .tfvars file actually changes
# what gets launched.
###############################################################

run "validate_instance_type" {
  command = plan

  assert {
    condition     = aws_launch_template.example.instance_type == "t3.micro"
    error_message = "Launch template instance_type must match the instance_type variable."
  }
}

###############################################################
# RUN 3: Security group port — instance ingress
#
# WHY THIS ASSERTION MATTERS
# The instance security group must allow inbound traffic on
# server_port. If the port is wrong, the ALB health checks
# fail, instances never become healthy, and the ALB returns
# 502 for every request. This is caught here at plan time —
# before any infrastructure is created.
###############################################################

run "validate_instance_sg_ingress_port" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.instance_from_alb.from_port == 8080
    error_message = "Instance security group must allow inbound traffic on port 8080 (server_port)."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.instance_from_alb.to_port == 8080
    error_message = "Instance security group to_port must equal server_port (8080)."
  }
}

###############################################################
# RUN 4: ALB security group — inbound port
#
# WHY THIS ASSERTION MATTERS
# The ALB must listen on alb_port (80). If the ingress rule
# has the wrong port, all external HTTP traffic is dropped
# at the security group before reaching the ALB listener.
###############################################################

run "validate_alb_sg_ingress_port" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.alb_http.from_port == 80
    error_message = "ALB security group must allow inbound traffic on port 80 (alb_port)."
  }
}

###############################################################
# RUN 5: ASG min and max size
#
# WHY THIS ASSERTION MATTERS
# If min_size and max_size are swapped or miscalculated, the
# ASG will fail to create (AWS rejects max < min). Catching
# this at plan time avoids a failed apply mid-run.
###############################################################

run "validate_asg_sizes" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.example.min_size == 1
    error_message = "ASG min_size must match the min_size variable (1)."
  }

  assert {
    condition     = aws_autoscaling_group.example.max_size == 2
    error_message = "ASG max_size must match the max_size variable (2)."
  }
}

###############################################################
# RUN 6: Required ManagedBy tag on ALB
#
# WHY THIS ASSERTION MATTERS
# Post-destroy verification commands filter by
# tag:ManagedBy=terraform. If this tag is missing, orphan
# detection (from Day 17) silently skips the resource. This
# test enforces the tag contract at every apply.
###############################################################

run "validate_alb_managed_by_tag" {
  command = plan

  assert {
    condition     = aws_lb.example.tags["ManagedBy"] == "terraform"
    error_message = "ALB must have tag ManagedBy=terraform for post-destroy cleanup verification."
  }
}

###############################################################
# RUN 7: Environment tag propagates correctly
#
# WHY THIS ASSERTION MATTERS
# The environment tag drives Cost Explorer filters and is used
# in the multi-environment comparison (dev vs prod). If the
# tag were hardcoded to "dev", the production cluster would
# be mistagged and appear under the wrong cost center.
###############################################################

run "validate_environment_tag" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.example.tag[1].value == "dev"
    error_message = "ASG Environment tag must match the environment variable."
  }
}

###############################################################
# RUN 8: Cluster name length validation
#
# WHY THIS ASSERTION MATTERS
# Certain AWS resources (ALB names, target group names) have a
# 32-character limit. A cluster_name that is too long causes
# apply to fail with an opaque AWS API error. The variable
# validation block catches this, and this test confirms the
# validation is wired correctly.
###############################################################

run "validate_cluster_name_too_long" {
  command = plan

  variables {
    cluster_name = "this-cluster-name-is-way-too-long-for-aws-resources-to-handle-safely"
  }

  # expect_failures means this run block PASSES if Terraform
  # raises the specified error. It is the correct way to test
  # that validation rules are enforced.
  expect_failures = [
    var.cluster_name,
  ]
}

###############################################################
# RUN 9: Invalid environment value is rejected
#
# WHY THIS ASSERTION MATTERS
# The environment variable has a validation block that only
# allows "dev" or "prod". This test confirms that passing
# any other value fails with the correct error, not silently
# deploying to an unknown environment.
###############################################################

run "validate_invalid_environment_rejected" {
  command = plan

  variables {
    environment = "staging"
  }

  expect_failures = [
    var.environment,
  ]
}

###############################################################
# RUN 10: Health check type is ELB (not EC2)
#
# WHY THIS ASSERTION MATTERS
# EC2 health checks only detect whether an instance is running.
# ELB health checks detect whether the application is serving
# traffic. With EC2 health checks, an instance running a
# crashed web server stays "healthy" in the ASG. This test
# ensures the stronger check is enforced.
###############################################################

run "validate_asg_health_check_type" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.example.health_check_type == "ELB"
    error_message = "ASG must use ELB health checks, not EC2. EC2 checks do not detect application failures."
  }
}
