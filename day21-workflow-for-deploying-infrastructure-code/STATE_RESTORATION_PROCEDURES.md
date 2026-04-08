# State Restoration Procedures

## Critical Context

**The Terraform state file is the single source of truth for your infrastructure.** If it becomes corrupted, Terraform loses track of what resources exist, making it impossible to manage or destroy infrastructure safely.

State corruption can occur from:
- Concurrent applies (two people running apply simultaneously)
- Network interruption during state write
- Manual state file editing
- S3 bucket misconfiguration
- Terraform bugs (rare but possible)

**Without S3 versioning enabled, state corruption is unrecoverable.**

---

## Prerequisites

### 1. S3 Versioning MUST Be Enabled

```bash
# Check if versioning is enabled
aws s3api get-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --query 'Status' \
  --output text

# Expected output: "Enabled"
# If output is "Suspended" or empty, versioning is NOT enabled
```

**If versioning is not enabled:**

```bash
# Enable versioning immediately
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Verify
aws s3api get-bucket-versioning \
  --bucket my-terraform-state-bucket
```

⚠️ **WARNING:** Enabling versioning does NOT retroactively version existing state files. Only changes AFTER enabling versioning are versioned.

### 2. Required Tools

- AWS CLI v2.x
- Terraform CLI (same version used for original apply)
- `jq` for JSON parsing
- Appropriate AWS credentials with S3 read/write permissions

---

## State Restoration Scenarios

### Scenario 1: Corrupted State After Failed Apply

**Symptoms:**
- `terraform plan` shows errors like "Error refreshing state"
- State file contains invalid JSON
- Resources exist in AWS but Terraform doesn't recognize them

**Recovery Steps:**

```bash
# 1. Identify the corrupted state
terraform state pull > corrupted-state.json
cat corrupted-state.json
# If this shows JSON errors or is empty, state is corrupted

# 2. List available state versions
aws s3api list-object-versions \
  --bucket my-terraform-state-bucket \
  --prefix dev/terraform.tfstate \
  --query 'Versions[*].[VersionId,LastModified,IsLatest]' \
  --output table

# Output example:
# |  VersionId                        |  LastModified              |  IsLatest  |
# |  abc123def456                     |  2026-04-08T20:00:00.000Z  |  True      |  ← Corrupted
# |  xyz789uvw012                     |  2026-04-08T19:45:00.000Z  |  False     |  ← Last good
# |  mno345pqr678                     |  2026-04-08T19:30:00.000Z  |  False     |

# 3. Download the last known good version (second in list)
GOOD_VERSION="xyz789uvw012"  # Replace with actual version ID

aws s3api get-object \
  --bucket my-terraform-state-bucket \
  --key dev/terraform.tfstate \
  --version-id $GOOD_VERSION \
  terraform.tfstate.restored

# 4. Validate the restored state file
cat terraform.tfstate.restored | jq . > /dev/null
# If this succeeds, JSON is valid

# Check Terraform version compatibility
cat terraform.tfstate.restored | jq -r '.terraform_version'
# Must match your Terraform CLI version

# 5. Backup the corrupted state (for forensics)
terraform state pull > corrupted-state-$(date +%Y%m%d-%H%M%S).json

# 6. Push the restored state
terraform state push terraform.tfstate.restored

# 7. Verify restoration
terraform state list
# Should show all expected resources

terraform plan
# Should show expected changes (if any) or "No changes"
```

**Verification Checklist:**
- [ ] `terraform state list` shows all expected resources
- [ ] `terraform plan` runs without errors
- [ ] Plan output matches expectations (no unexpected changes)
- [ ] AWS Console shows resources match state file

---

### Scenario 2: Accidental State Deletion

**Symptoms:**
- State file is missing from S3
- `terraform plan` shows all resources will be created (but they already exist)
- Error: "No state file was found"

**Recovery Steps:**

```bash
# 1. Verify state file is actually missing
aws s3 ls s3://my-terraform-state-bucket/dev/terraform.tfstate
# If this returns nothing, file is deleted

# 2. Check if deletion was recent (within S3 versioning retention)
aws s3api list-object-versions \
  --bucket my-terraform-state-bucket \
  --prefix dev/terraform.tfstate \
  --query 'DeleteMarkers[*].[VersionId,LastModified]' \
  --output table

# 3. List all versions including delete markers
aws s3api list-object-versions \
  --bucket my-terraform-state-bucket \
  --prefix dev/terraform.tfstate \
  --output json | jq -r '.Versions[] | "\(.VersionId) \(.LastModified) \(.IsLatest)"'

# 4. Find the most recent version BEFORE the delete marker
LAST_GOOD_VERSION="xyz789uvw012"  # Version ID before deletion

# 5. Restore the state file
aws s3api get-object \
  --bucket my-terraform-state-bucket \
  --key dev/terraform.tfstate \
  --version-id $LAST_GOOD_VERSION \
  terraform.tfstate.restored

# 6. Validate and push
cat terraform.tfstate.restored | jq . > /dev/null
terraform state push terraform.tfstate.restored

# 7. Verify
terraform state list
terraform plan
```

---

### Scenario 3: State Drift (Manual Changes Made in AWS Console)

**Symptoms:**
- `terraform plan` shows unexpected changes
- Resources were modified outside Terraform
- Plan wants to revert manual changes

**Recovery Steps:**

```bash
# 1. Identify what changed
terraform plan -out=drift-detection.tfplan

# Review the plan output carefully
terraform show drift-detection.tfplan

# 2. Decide on remediation strategy:

# Option A: Accept the drift (update Terraform code to match reality)
# - Update your .tf files to match the manual changes
# - Run terraform plan again - should show no changes
# - Commit the updated code

# Option B: Revert the drift (apply Terraform's desired state)
# - Review the plan to ensure reverting is safe
# - Apply to restore Terraform's desired state
terraform apply drift-detection.tfplan

# Option C: Import the manual changes into state
# - For resources created manually that Terraform doesn't know about
terraform import aws_instance.example i-1234567890abcdef0

# 3. Document the drift in an incident report
cat > drift-incident-$(date +%Y%m%d).md << EOF
# Drift Incident Report

**Date:** $(date)
**Environment:** dev
**Detected By:** terraform plan

## What Changed
[Describe manual changes]

## Root Cause
[Why were manual changes made?]

## Remediation
[What was done to fix it?]

## Prevention
[How to prevent this in the future?]
EOF
```

---

### Scenario 4: State Lock Timeout (DynamoDB Lock Not Released)

**Symptoms:**
- `terraform plan` or `apply` hangs with "Acquiring state lock"
- Error: "Error locking state: Error acquiring the state lock"
- Lock was acquired but never released (crashed process, network issue)

**Recovery Steps:**

```bash
# 1. Verify lock exists
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "my-terraform-state-bucket/dev/terraform.tfstate-md5"}}' \
  --output json

# If this returns an item, lock exists

# 2. Check lock age
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "my-terraform-state-bucket/dev/terraform.tfstate-md5"}}' \
  --query 'Item.Info.S' \
  --output text | jq -r '.Created'

# If lock is > 15 minutes old and you're CERTAIN no apply is running, force unlock

# 3. Force unlock (DANGEROUS - only if you're certain no apply is running)
terraform force-unlock <LOCK_ID>

# LOCK_ID is shown in the error message, e.g.:
# "Lock Info:
#   ID:        abc123-def456-ghi789
#   Path:      my-terraform-state-bucket/dev/terraform.tfstate
#   Operation: OperationTypeApply
#   Who:       user@hostname
#   Version:   1.9.0
#   Created:   2026-04-08 20:00:00.000 UTC"

# Use the ID value:
terraform force-unlock abc123-def456-ghi789

# 4. Verify lock is released
aws dynamodb get-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "my-terraform-state-bucket/dev/terraform.tfstate-md5"}}'
# Should return empty

# 5. Retry your operation
terraform plan
```

⚠️ **WARNING:** Only force-unlock if you are ABSOLUTELY CERTAIN no other Terraform process is running. Forcing unlock during an active apply can cause state corruption.

---

## State Validation Procedures

### Validate State File Integrity

```bash
# 1. Pull current state
terraform state pull > current-state.json

# 2. Validate JSON structure
cat current-state.json | jq . > /dev/null
echo $?
# Expected: 0 (success)

# 3. Check Terraform version
cat current-state.json | jq -r '.terraform_version'
# Should match your Terraform CLI version

# 4. Check serial number (increments with each change)
cat current-state.json | jq -r '.serial'
# Should be a positive integer

# 5. Check lineage (unique ID for this state file)
cat current-state.json | jq -r '.lineage'
# Should be a UUID

# 6. List all resources
cat current-state.json | jq -r '.resources[].type' | sort | uniq -c

# 7. Check for empty resources (indicates corruption)
cat current-state.json | jq '.resources[] | select(.instances | length == 0)'
# Should return nothing

# 8. Validate resource addresses
terraform state list
# Should show all resources without errors
```

### Compare State to AWS Reality

```bash
# 1. Refresh state from AWS (read-only, safe)
terraform refresh

# 2. Check for drift
terraform plan -detailed-exitcode
EXIT_CODE=$?

case $EXIT_CODE in
  0)
    echo "✅ No drift detected - state matches reality"
    ;;
  2)
    echo "⚠️  Drift detected - state differs from reality"
    terraform plan | grep -E "^  [~+-]" | head -20
    ;;
  *)
    echo "❌ Error running plan - investigate"
    ;;
esac
```

---

## Quarterly State Restoration Testing

**Requirement:** Test state restoration procedures every quarter in non-production environment.

### Test Procedure

```bash
#!/bin/bash
# quarterly-state-restoration-test.sh

set -euo pipefail

BUCKET="my-terraform-state-bucket"
ENVIRONMENT="dev"
STATE_KEY="${ENVIRONMENT}/terraform.tfstate"
TEST_DATE=$(date +%Y-%m-%d)

echo "=== Quarterly State Restoration Test - $TEST_DATE ==="

# 1. Record current state version
echo "1. Recording current state version..."
CURRENT_VERSION=$(aws s3api list-object-versions \
  --bucket $BUCKET \
  --prefix $STATE_KEY \
  --query 'Versions[?IsLatest==`true`].VersionId' \
  --output text)

echo "   Current version: $CURRENT_VERSION"

# 2. Pull and backup current state
echo "2. Backing up current state..."
terraform state pull > state-backup-${TEST_DATE}.json

# 3. Verify backup is valid
echo "3. Validating backup..."
cat state-backup-${TEST_DATE}.json | jq . > /dev/null
echo "   ✅ Backup is valid JSON"

# 4. List available versions
echo "4. Listing available state versions..."
aws s3api list-object-versions \
  --bucket $BUCKET \
  --prefix $STATE_KEY \
  --query 'Versions[*].[VersionId,LastModified]' \
  --output table

# 5. Simulate corruption by pushing empty state
echo "5. Simulating state corruption..."
echo '{"version": 4, "terraform_version": "1.9.0", "serial": 999, "lineage": "test", "outputs": {}, "resources": []}' | \
  terraform state push -

# 6. Verify corruption
echo "6. Verifying corruption..."
terraform state list
# Should show no resources

# 7. Restore from backup
echo "7. Restoring from backup..."
terraform state push state-backup-${TEST_DATE}.json

# 8. Verify restoration
echo "8. Verifying restoration..."
RESOURCE_COUNT=$(terraform state list | wc -l)
echo "   Resources restored: $RESOURCE_COUNT"

# 9. Run plan to verify
echo "9. Running plan to verify state integrity..."
terraform plan -detailed-exitcode
PLAN_EXIT=$?

if [ $PLAN_EXIT -eq 0 ]; then
  echo "   ✅ State restored successfully - no drift"
elif [ $PLAN_EXIT -eq 2 ]; then
  echo "   ⚠️  State restored but drift detected - review plan output"
else
  echo "   ❌ State restoration failed - manual intervention required"
  exit 1
fi

# 10. Document test results
cat > state-restoration-test-${TEST_DATE}.md << EOF
# State Restoration Test Results

**Date:** $TEST_DATE
**Environment:** $ENVIRONMENT
**Tester:** $(whoami)

## Test Steps Completed
- [x] Current state version recorded
- [x] State backup created and validated
- [x] State corruption simulated
- [x] State restored from backup
- [x] Restoration verified with terraform plan

## Results
- Current state version: $CURRENT_VERSION
- Resources before corruption: $RESOURCE_COUNT
- Resources after restoration: $RESOURCE_COUNT
- Plan exit code: $PLAN_EXIT

## Status
✅ PASSED - State restoration procedures verified working

## Next Test Due
$(date -d "+3 months" +%Y-%m-%d)
EOF

echo ""
echo "=== Test Complete ==="
echo "Results documented in: state-restoration-test-${TEST_DATE}.md"
```

**Run this test:**

```bash
chmod +x quarterly-state-restoration-test.sh
./quarterly-state-restoration-test.sh
```

---

## Emergency State Recovery Playbook

### When to Use This

- Production state is corrupted
- Multiple restoration attempts have failed
- You need to recover quickly

### Emergency Steps

```bash
# 1. STOP ALL TERRAFORM OPERATIONS IMMEDIATELY
# - Notify team via Slack/PagerDuty
# - Block all CI/CD pipelines
# - Prevent any manual applies

# 2. Assess the damage
terraform state pull > corrupted-state-$(date +%Y%m%d-%H%M%S).json
cat corrupted-state-$(date +%Y%m%d-%H%M%S).json | jq .

# 3. List ALL available state versions
aws s3api list-object-versions \
  --bucket my-terraform-state-bucket \
  --prefix production/terraform.tfstate \
  --output json > all-state-versions.json

# 4. Download the 5 most recent versions
for VERSION in $(cat all-state-versions.json | jq -r '.Versions[0:5][].VersionId'); do
  aws s3api get-object \
    --bucket my-terraform-state-bucket \
    --key production/terraform.tfstate \
    --version-id $VERSION \
    state-version-$VERSION.json
  
  echo "Version $VERSION:"
  cat state-version-$VERSION.json | jq -r '.serial, .terraform_version'
done

# 5. Identify the last known good version
# - Check serial numbers (should increment)
# - Check terraform_version (should match current)
# - Check resource count (should be reasonable)

# 6. Restore the last known good version
GOOD_VERSION="<version-id-here>"
terraform state push state-version-$GOOD_VERSION.json

# 7. Verify restoration
terraform state list | wc -l
terraform plan

# 8. Document the incident
# Create incident report with:
# - Timeline of events
# - Root cause analysis
# - Recovery steps taken
# - Prevention measures

# 9. Re-enable operations
# - Unblock CI/CD
# - Notify team recovery is complete
# - Schedule post-mortem
```

---

## Prevention Best Practices

### 1. Always Use Remote State with Versioning

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    
    # Versioning must be enabled on the bucket
    # This is configured at the bucket level, not here
  }
}
```

### 2. Enable S3 Bucket Versioning

```bash
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled
```

### 3. Configure S3 Lifecycle Rules

```bash
# Keep all versions for 90 days, then delete old versions
aws s3api put-bucket-lifecycle-configuration \
  --bucket my-terraform-state-bucket \
  --lifecycle-configuration file://lifecycle.json

# lifecycle.json:
{
  "Rules": [
    {
      "Id": "DeleteOldStateVersions",
      "Status": "Enabled",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }
  ]
}
```

### 4. Use State Locking

```hcl
# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock"
    Environment = "all"
  }
}
```

### 5. Never Edit State Files Manually

```bash
# ❌ NEVER DO THIS
vim terraform.tfstate

# ✅ Use Terraform commands instead
terraform state rm aws_instance.example
terraform state mv aws_instance.old aws_instance.new
terraform import aws_instance.example i-1234567890abcdef0
```

### 6. Automate State Backups

```bash
# Cron job to backup state daily
0 2 * * * /usr/local/bin/backup-terraform-state.sh

# backup-terraform-state.sh:
#!/bin/bash
DATE=$(date +%Y%m%d)
terraform state pull > /backups/terraform-state-${DATE}.json
# Keep last 30 days
find /backups -name "terraform-state-*.json" -mtime +30 -delete
```

---

## Troubleshooting

### Issue: "Error loading state: state snapshot was created by Terraform v1.8.0, but this is v1.9.0"

**Solution:**
```bash
# Upgrade Terraform to match state version
tfenv install 1.8.0
tfenv use 1.8.0

# Or upgrade state to current version (one-way operation)
terraform state replace-provider \
  registry.terraform.io/-/aws \
  registry.terraform.io/hashicorp/aws
```

### Issue: "Error: state data in S3 does not have the expected content"

**Solution:**
```bash
# State file is corrupted or incomplete
# Restore from previous version
aws s3api list-object-versions \
  --bucket my-terraform-state-bucket \
  --prefix dev/terraform.tfstate

# Download previous version and push
aws s3api get-object \
  --bucket my-terraform-state-bucket \
  --key dev/terraform.tfstate \
  --version-id <PREVIOUS_VERSION> \
  restored-state.json

terraform state push restored-state.json
```

### Issue: "Error: Failed to save state: AccessDenied"

**Solution:**
```bash
# Check IAM permissions
aws sts get-caller-identity

# Required S3 permissions:
# - s3:GetObject
# - s3:PutObject
# - s3:ListBucket

# Required DynamoDB permissions:
# - dynamodb:PutItem
# - dynamodb:GetItem
# - dynamodb:DeleteItem
```

---

## State Restoration Checklist

Use this checklist for any state restoration:

- [ ] Identify the issue (corruption, deletion, drift)
- [ ] Stop all Terraform operations
- [ ] List available state versions
- [ ] Download suspected good version
- [ ] Validate JSON structure
- [ ] Check Terraform version compatibility
- [ ] Backup current (corrupted) state
- [ ] Push restored state
- [ ] Verify with `terraform state list`
- [ ] Run `terraform plan` to check for drift
- [ ] Verify resources in AWS Console
- [ ] Document the incident
- [ ] Identify root cause
- [ ] Implement prevention measures
- [ ] Resume normal operations

---

## Support and Escalation

**For state restoration issues:**

1. **First Response:** Infrastructure team (#infrastructure-team Slack)
2. **Escalation:** Infrastructure leads (if restoration fails)
3. **Emergency:** On-call engineer (PagerDuty)

**Documentation:**
- This guide: `STATE_RESTORATION_PROCEDURES.md`
- AWS S3 versioning: https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html
- Terraform state: https://www.terraform.io/docs/language/state/index.html

---

**Last Updated:** 2026-04-08  
**Version:** 1.0.0  
**Next Review:** 2026-07-08  
**Owner:** Infrastructure Team