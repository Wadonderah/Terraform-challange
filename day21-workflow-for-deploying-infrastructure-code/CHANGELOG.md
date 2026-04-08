# Changelog

All notable changes to the webserver-cluster module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Compliance audit report documenting workflow gaps
- CODEOWNERS file for required reviewers
- Pre-commit hooks configuration
- Git commit message template
- This CHANGELOG file

## [1.0.0] - 2026-04-08

### Added
- CloudWatch metric alarms for CPU utilization (high/low thresholds)
- CloudWatch metric alarms for ALB 5xx errors
- CloudWatch metric alarm for unhealthy host detection
- SNS topic for centralized alert notifications with KMS encryption
- Optional email subscription to SNS alerts topic
- CloudWatch dashboard with CPU metrics, ALB metrics, and alarm status
- Comprehensive unit tests for CloudWatch alarm configuration
- GitHub Actions CI pipeline with fmt, validate, tflint, tfsec, plan, and test jobs
- Sentinel policies for instance type restrictions and cost estimation
- Safe-apply deployment script with state versioning verification
- State version listing script for rollback scenarios
- Pull request template for infrastructure changes
- Deployment verification with post-apply clean plan check
- Destructive change safeguards with mandatory confirmation

### Configuration
- `cpu_high_threshold` variable (default: 80%)
- `cpu_low_threshold` variable (default: 10%)
- `alb_5xx_threshold` variable (default: 10 errors/min)
- `alert_email` variable for SNS email subscriptions

### Outputs
- `asg_name` - Auto Scaling Group name for metric filtering
- `asg_arn` - Auto Scaling Group ARN
- `alb_dns_name` - Application Load Balancer DNS name
- `alb_arn_suffix` - ALB ARN suffix for CloudWatch dimensions
- `cloudwatch_dashboard_url` - Direct link to CloudWatch dashboard
- `alarm_arns` - Map of all alarm ARNs
- `sns_topic_arn` - SNS alerts topic ARN

### Security
- All CloudWatch alarms treat missing data as "notBreaching" to prevent false positives
- SNS topic encrypted at rest with AWS-managed KMS key
- EBS encryption enforced via Sentinel policy
- No hardcoded credentials (OIDC authentication for AWS)
- tfsec security scanning in CI pipeline

### Infrastructure
- Terraform 1.9.0
- AWS Provider (compatible with latest)
- S3 backend with versioning for state management
- Terraform Cloud integration for Sentinel policies

## [0.1.0] - Initial Development

### Added
- Basic webserver cluster module structure
- Auto Scaling Group configuration
- Application Load Balancer setup
- Launch template for EC2 instances
- Security groups for ALB and instances
- Basic outputs for cluster endpoints

---

## Version Numbering

This project uses [Semantic Versioning](https://semver.org/):

- **MAJOR** version (X.0.0): Incompatible API changes or breaking infrastructure changes
- **MINOR** version (0.X.0): New functionality in a backwards-compatible manner
- **PATCH** version (0.0.X): Backwards-compatible bug fixes

### Breaking Changes

Breaking changes will be clearly marked in the changelog with a **BREAKING CHANGE** label and migration instructions.

### Deprecation Policy

Features marked as deprecated will be supported for at least one minor version before removal.

---

## How to Use This Changelog

### For Module Consumers

When upgrading the module version, review the changelog for:
1. New features you can leverage
2. Breaking changes requiring code updates
3. Deprecated features to migrate away from
4. Security fixes that may require immediate action

### For Module Contributors

When making changes:
1. Add entries under `[Unreleased]` section
2. Use categories: Added, Changed, Deprecated, Removed, Fixed, Security
3. Include ticket/PR references
4. Describe user impact, not implementation details
5. Move entries to versioned section when releasing

---

## Release Process

1. Update CHANGELOG.md with version number and date
2. Create git tag: `git tag -a "vX.Y.Z" -m "Release vX.Y.Z"`
3. Push tag: `git push origin vX.Y.Z`
4. Update module references in consuming repositories
5. Announce release in team channels

---

[Unreleased]: https://github.com/your-org/repo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-org/repo/releases/tag/v1.0.0
[0.1.0]: https://github.com/your-org/repo/releases/tag/v0.1.0