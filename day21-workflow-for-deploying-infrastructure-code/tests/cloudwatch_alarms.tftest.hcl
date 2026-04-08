# ==============================================================================
# tests/cloudwatch_alarms.tftest.hcl
#
# Unit tests for the CloudWatch alarm configuration added in Day 21.
# Uses Terraform's native testing framework (1.6+) — no external tools needed.
#
# Run locally: terraform test
# These tests use mock providers so no AWS credentials are required.
# ==============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# Mock providers — unit tests never hit real AWS
# ─────────────────────────────────────────────────────────────────────────────

mock_provider "aws" {
  mock_resource "aws_autoscaling_group" {
    defaults = {
      name = "mock-asg"
      arn  = "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:mock"
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      dns_name   = "mock-alb.us-east-1.elb.amazonaws.com"
      arn        = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/mock/abc123"
      arn_suffix = "app/mock/abc123"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn        = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/mock/abc123"
      arn_suffix = "targetgroup/mock/abc123"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 1: Default alarm thresholds are within safe ranges
# ─────────────────────────────────────────────────────────────────────────────

run "default_thresholds_are_valid" {
  command = plan

  variables {
    cluster_name       = "test-cluster"
    cpu_high_threshold = 80
    cpu_low_threshold  = 10
    alb_5xx_threshold  = 10
    alert_email        = ""
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cpu_high.threshold == 80
    error_message = "CPU high alarm threshold should default to 80%"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cpu_high.comparison_operator == "GreaterThanThreshold"
    error_message = "CPU high alarm must use GreaterThanThreshold comparison"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cpu_low.threshold == 10
    error_message = "CPU low alarm threshold should default to 10%"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cpu_low.evaluation_periods == 3
    error_message = "CPU low alarm needs 3 evaluation periods to avoid premature scale-in"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cpu_high.evaluation_periods == 2
    error_message = "CPU high alarm should use 2 evaluation periods"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 2: Alarm names are deterministic and cluster-scoped
# ─────────────────────────────────────────────────────────────────────────────

run "alarm_names_are_cluster_scoped" {
  command = plan

  variables {
    cluster_name = "webserver-prod"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cpu_high.alarm_name == "webserver-prod-cpu-high"
    error_message = "CPU high alarm name must be prefixed with cluster_name"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.unhealthy_hosts.alarm_name == "webserver-prod-unhealthy-hosts"
    error_message = "Unhealthy hosts alarm name must be prefixed with cluster_name"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 3: Missing data is treated as non-breaching (alarms don't fire on gaps)
# ─────────────────────────────────────────────────────────────────────────────

run "missing_data_treated_as_not_breaching" {
  command = plan

  variables {
    cluster_name = "test-cluster"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.cpu_high.treat_missing_data == "notBreaching"
    error_message = "Missing metric data should not trigger the alarm — prevents false positives during deployments"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx_errors.treat_missing_data == "notBreaching"
    error_message = "ALB alarm must treat missing data as notBreaching"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 4: SNS topic is created, email subscription is conditional
# ─────────────────────────────────────────────────────────────────────────────

run "sns_topic_created_without_email" {
  command = plan

  variables {
    cluster_name = "test-cluster"
    alert_email  = ""
  }

  assert {
    condition     = aws_sns_topic.alerts.name == "test-cluster-alerts"
    error_message = "SNS topic name must follow cluster_name naming convention"
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email_alerts) == 0
    error_message = "No email subscription should be created when alert_email is empty"
  }
}

run "sns_email_subscription_created_when_email_provided" {
  command = plan

  variables {
    cluster_name = "test-cluster"
    alert_email  = "oncall@example.com"
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email_alerts) == 1
    error_message = "Email subscription must be created when alert_email is provided"
  }

  assert {
    condition     = aws_sns_topic_subscription.email_alerts[0].protocol == "email"
    error_message = "SNS subscription protocol must be 'email'"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Test 5: SNS topic has encryption at rest
# ─────────────────────────────────────────────────────────────────────────────

run "sns_topic_is_encrypted" {
  command = plan

  variables {
    cluster_name = "test-cluster"
  }

  assert {
    condition     = aws_sns_topic.alerts.kms_master_key_id != null
    error_message = "SNS topic must have KMS encryption enabled — required for compliance"
  }
}
