# Day 21 - Commands to Run

## Quick Reference: Complete Command Execution Guide

This guide provides the exact commands to run for the Day 21 infrastructure deployment workflow.

---

## 📍 Working Directory

All commands should be run from:
```bash
cd c:/Users/wadon/Startups/Terraform-challange/day21-workflow-for-deploying-infrastructure-code
```

---

## 🚀 Initial Setup (One-Time)

### 1. Install Required Tools

**On Windows (PowerShell):**
```powershell
# Install Terraform (if not already installed)
# Download from: https://www.terraform.io/downloads

# Install AWS CLI
# Download from: https://aws.amazon.com/cli/

# Install Python and pre-commit
pip install pre-commit

# Install pre-commit hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Configure git commit template
git config commit.template .gitmessage

# Verify installations
terraform version
aws --version
pre-commit --version
```

### 2. Configure AWS Credentials

```powershell
# Configure AWS credentials
aws configure

# Test AWS access
aws sts get-caller-identity
```

### 3. Initialize Terraform Backend (First Time Only)

**Create S3 bucket for state:**
```powershell
# Set your bucket name
$BUCKET_NAME = "my-terraform-state-bucket-$(Get-Random)"
$REGION = "us-east-1"

# Create S3 bucket
aws s3api create-bucket `
  --bucket $BUCKET_NAME `
  --region $REGION

# Enable versioning (CRITICAL for state recovery)
aws s3api put-bucket-versioning `
  --bucket $BUCKET_NAME `
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption `
  --bucket $BUCKET_NAME `
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table `
  --table-name terraform-state-lock `
  --attribute-definitions AttributeName=LockID,AttributeType=S `
  --key-schema AttributeName=LockID,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST `
  --region $REGION

# Verify bucket versioning
aws s3api get-bucket-versioning --bucket $BUCKET_NAME
```

### 4. Configure Backend in Terraform

**Create `backend.tf`:**
```powershell
# Create backend configuration
@"
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "dev/terraform.tfstate"
    region         = "$REGION"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
"@ | Out-File -FilePath backend.tf -Encoding UTF8
```

---

## 📝 Daily Workflow Commands

### Step 1: Create Feature Branch

```powershell
# Ensure you're on main and up to date
git checkout main
git pull origin main

# Create feature branch
git checkout -b add-monitoring-feature

# Verify branch
git branch
```

### Step 2: Initialize Terraform

```powershell
# Initialize Terraform (downloads providers)
terraform init

# Verify initialization
terraform version
```

### Step 3: Select Workspace

```powershell
# List available workspaces
terraform workspace list

# Select dev workspace (or create if doesn't exist)
terraform workspace select dev

# If workspace doesn't exist, create it:
# terraform workspace new dev

# Verify current workspace
terraform workspace show
```

### Step 4: Format and Validate Code

```powershell
# Format all Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Expected output: "Success! The configuration is valid."
```

### Step 5: Generate Plan

```powershell
# Generate and save plan
terraform plan -out=day21.tfplan

# Review the plan output carefully
# Look for:
# - Plan: X to add, Y to change, Z to destroy
# - Resource types being created/modified/destroyed
# - Any unexpected changes
```

### Step 6: Review Plan in Detail

```powershell
# Show plan in human-readable format
terraform show day21.tfplan

# Show plan in JSON format (for analysis)
terraform show -json day21.tfplan | ConvertFrom-Json | ConvertTo-Json -Depth 10

# Count resources by action
terraform show -json day21.tfplan | `
  ConvertFrom-Json | `
  Select-Object -ExpandProperty resource_changes | `
  Group-Object -Property {$_.change.actions} | `
  Select-Object Name, Count
```

### Step 7: Analyze Blast Radius (Optional)

```powershell
# Run blast radius analysis script
bash scripts/analyze-blast-radius.sh day21.tfplan

# Or manually check for shared resources
terraform show -json day21.tfplan | `
  ConvertFrom-Json | `
  Select-Object -ExpandProperty resource_changes | `
  Where-Object {$_.type -match "vpc|security_group|iam_role|subnet"} | `
  Select-Object type, name, @{Name="actions";Expression={$_.change.actions}}
```

### Step 8: Commit Changes

```powershell
# Stage all changes
git add .

# Commit with template (editor will open)
git commit

# Fill in the template with:
# - What changed
# - Terraform plan summary (created/modified/destroyed counts)
# - Blast radius analysis
# - Testing checklist

# Example commit message:
<#
infra: Add CloudWatch alarms to webserver cluster

## What Changed
- Added 4 CloudWatch alarms for CPU and ALB metrics
- Created SNS topic for alert notifications
- Deployed CloudWatch dashboard for cluster visibility

## Terraform Plan Summary
Created: 7 | Modified: 0 | Destroyed: 0

## Blast Radius
- All changes are additive (no modifications to existing resources)
- If apply fails after SNS topic creation, orphaned topic can be cleaned up
- No production traffic affected
- No shared resources modified

## Testing
- [x] terraform fmt passed
- [x] terraform validate passed
- [x] terraform plan reviewed
- [x] Blast radius analyzed

Closes #123
#>
```

### Step 9: Push Branch

```powershell
# Push feature branch to remote
git push origin add-monitoring-feature

# If this is the first push:
git push --set-upstream origin add-monitoring-feature
```

### Step 10: Create Pull Request

```powershell
# Open GitHub in browser to create PR
Start-Process "https://github.com/YOUR-USERNAME/Terraform-challange/compare/main...add-monitoring-feature"

# Or use GitHub CLI if installed:
gh pr create --title "Add CloudWatch monitoring" --body "See commit message for details"
```

**In the PR, include:**
- Full `terraform plan` output
- Resource counts (created/modified/destroyed)
- Blast radius analysis
- Rollback plan

### Step 11: Wait for CI/CD Checks

GitHub Actions will automatically run:
- ✅ Format check
- ✅ Validation
- ✅ TFLint
- ✅ tfsec
- ✅ Plan (output posted to PR)
- ✅ Tests

### Step 12: After PR Approval - Merge

```powershell
# Merge PR via GitHub UI or CLI
gh pr merge --squash

# Pull latest main
git checkout main
git pull origin main
```

### Step 13: Tag Release

```powershell
# Create semantic version tag
git tag -a "v1.4.0" -m "Add CloudWatch alarms and dashboard

Features:
- CPU high/low alarms
- ALB 5xx error alarm
- Unhealthy host alarm
- SNS topic for alerts
- CloudWatch dashboard

Breaking Changes: None
Migration: None required"

# Push tag
git push origin v1.4.0

# Verify tag
git tag -l
git show v1.4.0
```

### Step 14: Apply Changes (Deployment)

```powershell
# Ensure you're on latest main
git checkout main
git pull origin main

# Select workspace
terraform workspace select dev

# Generate fresh plan
terraform plan -out=deploy.tfplan

# Review plan one more time
terraform show deploy.tfplan

# Apply using safe-apply script (with all safeguards)
bash scripts/safe-apply.sh deploy.tfplan my-terraform-state-bucket dev

# The script will:
# 1. Verify S3 versioning is enabled
# 2. Record pre-apply state version
# 3. Show plan summary
# 4. Require confirmation (type "yes")
# 5. If destructions detected, require typing "DESTROY"
# 6. Apply the plan
# 7. Run post-apply validation
# 8. Print rollback instructions
```

### Step 15: Verify Deployment

```powershell
# Run plan again - should show no changes
terraform plan

# Expected output: "No changes. Your infrastructure matches the configuration."

# List all resources in state
terraform state list

# Check specific resource
terraform state show aws_cloudwatch_metric_alarm.cpu_high

# Verify in AWS Console
Start-Process "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:"
```

---

## 🔧 Common Operations

### View Current State

```powershell
# List all resources
terraform state list

# Show specific resource
terraform state show aws_instance.example

# Pull entire state (for backup)
terraform state pull > state-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').json
```

### Check for Drift

```powershell
# Refresh state from AWS (read-only)
terraform refresh

# Check for drift
terraform plan -detailed-exitcode

# Exit codes:
# 0 = No changes (no drift)
# 2 = Changes detected (drift exists)
# Other = Error
```

### List State Versions

```powershell
# List available state versions
bash scripts/list-state-versions.sh my-terraform-state-bucket dev 10

# Or manually:
aws s3api list-object-versions `
  --bucket my-terraform-state-bucket `
  --prefix dev/terraform.tfstate `
  --query 'Versions[*].[VersionId,LastModified,IsLatest]' `
  --output table
```

### Run Tests

```powershell
# Run Terraform native tests
terraform test

# Run pre-commit hooks manually
pre-commit run --all-files

# Run specific checks
terraform fmt -check -recursive
terraform validate
```

### Destroy Resources (Careful!)

```powershell
# Generate destroy plan
terraform plan -destroy -out=destroy.tfplan

# Review destroy plan carefully
terraform show destroy.tfplan

# Apply destroy (requires confirmation)
terraform apply destroy.tfplan
```

---

## 🚨 Emergency Procedures

### Force Unlock State

```powershell
# If state is locked and you're CERTAIN no apply is running
terraform force-unlock <LOCK_ID>

# Get lock ID from error message
```

### Restore State from Backup

```powershell
# List available versions
aws s3api list-object-versions `
  --bucket my-terraform-state-bucket `
  --prefix dev/terraform.tfstate

# Download specific version
aws s3api get-object `
  --bucket my-terraform-state-bucket `
  --key dev/terraform.tfstate `
  --version-id <VERSION_ID> `
  terraform.tfstate.restored

# Validate restored state
Get-Content terraform.tfstate.restored | ConvertFrom-Json | ConvertTo-Json -Depth 10

# Push restored state
terraform state push terraform.tfstate.restored

# Verify restoration
terraform state list
terraform plan
```

### Rollback Deployment

```powershell
# Option 1: Revert the merge commit
git revert <MERGE_COMMIT_SHA>
git push origin main

# Then apply the revert
terraform plan -out=rollback.tfplan
bash scripts/safe-apply.sh rollback.tfplan my-terraform-state-bucket dev

# Option 2: Restore previous state version
# See STATE_RESTORATION_PROCEDURES.md for detailed steps
```

---

## 📊 Monitoring and Compliance

### Check Compliance

```powershell
# Run compliance verification
bash scripts/verify-compliance.sh

# Check branch protection
gh api repos/:owner/:repo/branches/main/protection

# List recent commits
git log --oneline -10

# Check for direct commits to main (should be none)
git log --first-parent main --oneline -20
```

### View CloudWatch Alarms

```powershell
# List all alarms
aws cloudwatch describe-alarms `
  --query 'MetricAlarms[*].[AlarmName,StateValue]' `
  --output table

# Get alarm details
aws cloudwatch describe-alarms `
  --alarm-names "dev-webserver-cluster-cpu-high"
```

### View SNS Topics

```powershell
# List SNS topics
aws sns list-topics

# Get topic details
aws sns get-topic-attributes `
  --topic-arn "arn:aws:sns:us-east-1:123456789012:dev-webserver-cluster-alerts"
```

---

## 🔍 Troubleshooting Commands

### Debug Terraform Issues

```powershell
# Enable debug logging
$env:TF_LOG = "DEBUG"
terraform plan

# Disable debug logging
$env:TF_LOG = ""

# Check Terraform version
terraform version

# Verify provider versions
terraform providers
```

### Check AWS Permissions

```powershell
# Verify AWS identity
aws sts get-caller-identity

# Test S3 access
aws s3 ls s3://my-terraform-state-bucket/

# Test DynamoDB access
aws dynamodb describe-table --table-name terraform-state-lock
```

### Validate Configuration

```powershell
# Check for syntax errors
terraform validate

# Format check (don't modify)
terraform fmt -check -recursive

# Show what would be formatted
terraform fmt -diff -recursive
```

---

## 📚 Reference Commands

### Git Operations

```powershell
# View commit history
git log --oneline --graph --all -20

# View file changes
git diff main..HEAD

# View specific file history
git log --follow -- modules/webserver-cluster/cloudwatch.tf

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

### Terraform State Operations

```powershell
# Move resource in state
terraform state mv aws_instance.old aws_instance.new

# Remove resource from state (doesn't destroy)
terraform state rm aws_instance.example

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0

# Replace provider
terraform state replace-provider `
  registry.terraform.io/-/aws `
  registry.terraform.io/hashicorp/aws
```

### AWS CLI Helpers

```powershell
# List EC2 instances
aws ec2 describe-instances `
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' `
  --output table

# List security groups
aws ec2 describe-security-groups `
  --query 'SecurityGroups[*].[GroupId,GroupName]' `
  --output table

# List CloudWatch dashboards
aws cloudwatch list-dashboards
```

---

## 🎯 Complete Workflow Example

Here's a complete end-to-end example:

```powershell
# 1. Start from main
cd c:/Users/wadon/Startups/Terraform-challange/day21-workflow-for-deploying-infrastructure-code
git checkout main
git pull origin main

# 2. Create feature branch
git checkout -b add-monitoring-alarms

# 3. Initialize and select workspace
terraform init
terraform workspace select dev

# 4. Make changes (edit .tf files)
# ... edit modules/webserver-cluster/cloudwatch.tf ...

# 5. Format and validate
terraform fmt -recursive
terraform validate

# 6. Generate plan
terraform plan -out=feature.tfplan

# 7. Review plan
terraform show feature.tfplan

# 8. Commit changes
git add .
git commit  # Fill in template

# 9. Push branch
git push origin add-monitoring-alarms

# 10. Create PR (via GitHub UI or CLI)
gh pr create --title "Add monitoring alarms" --body "See commit for details"

# 11. Wait for CI checks to pass

# 12. After approval, merge PR

# 13. Pull latest main
git checkout main
git pull origin main

# 14. Tag release
git tag -a "v1.4.0" -m "Add monitoring alarms"
git push origin v1.4.0

# 15. Deploy
terraform workspace select dev
terraform plan -out=deploy.tfplan
bash scripts/safe-apply.sh deploy.tfplan my-terraform-state-bucket dev

# 16. Verify
terraform plan  # Should show "No changes"
aws cloudwatch describe-alarms --query 'MetricAlarms[*].AlarmName'
```

---

## 📖 Additional Resources

- **Full Documentation:** `README.md`
- **Quick Start:** `QUICK_START.md`
- **Implementation Guide:** `IMPLEMENTATION_GUIDE.md`
- **State Restoration:** `STATE_RESTORATION_PROCEDURES.md`
- **Infrastructure vs Application:** `INFRASTRUCTURE_VS_APPLICATION_DEPLOYMENT.md`
- **Compliance Audit:** `COMPLIANCE_AUDIT_REPORT.md`

---

**Last Updated:** 2026-04-08  
**Version:** 1.0.0  
**Maintained by:** Infrastructure Team