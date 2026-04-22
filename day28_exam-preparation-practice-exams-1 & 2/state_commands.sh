# =============================================================================
# state_commands.sh
# Day 28: Terraform Associate Exam Prep - State Management Cheat Sheet
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# Run these commands AFTER terraform apply to practice state management.
# Every command here maps to a wrong answer from the Day 28 practice exams.
# =============================================================================

#!/bin/bash
set -e

echo "=================================================================="
echo "Day 28 - State Management Practice Commands"
echo "30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps"
echo "=================================================================="

# ------------------------------------------------------------------
# 1. List all resources Terraform knows about
# EXAM NOTE: This reads STATE only. Does not contact AWS.
# ------------------------------------------------------------------
echo ""
echo "--- 1. terraform state list ---"
terraform state list

# ------------------------------------------------------------------
# 2. Show detailed state of a specific resource
# ------------------------------------------------------------------
echo ""
echo "--- 2. terraform state show (S3 bucket) ---"
terraform state show module.state_demo.aws_s3_bucket.demo

# ------------------------------------------------------------------
# 3. Move resource to a new address in state
# EXAM NOTE: Does NOT change real infrastructure.
#            Bucket keeps its name and keeps running.
#            Only the Terraform address changes in state.
# ------------------------------------------------------------------
echo ""
echo "--- 3. terraform state mv (rename in state only) ---"
terraform state mv \
  module.state_demo.aws_s3_bucket.demo \
  module.state_demo.aws_s3_bucket.renamed
echo "Bucket still exists in AWS - only the state address changed."

# ------------------------------------------------------------------
# 4. Remove resource from state WITHOUT destroying it
# EXAM TRAP: terraform state rm != terraform destroy
#
# terraform state rm  -> removes from state, real resource SURVIVES
# terraform destroy   -> removes from state AND deletes real resource
# ------------------------------------------------------------------
echo ""
echo "--- 4. terraform state rm (removes from state, NOT from AWS) ---"
terraform state rm module.state_demo.aws_s3_bucket.renamed
echo "Bucket is still in AWS but Terraform no longer manages it."
echo "Verify with: aws s3 ls | grep state-demo"

# ------------------------------------------------------------------
# 5. Pull the raw state JSON
# EXAM NOTE: Sensitive outputs are PLAINTEXT in this JSON.
#            sensitive = true suppresses CLI display only.
# ------------------------------------------------------------------
echo ""
echo "--- 5. terraform state pull (raw state JSON) ---"
terraform state pull | python3 -m json.tool | grep -A3 "db_password" || true
echo "Notice: sensitive values are plaintext in state."

# ------------------------------------------------------------------
# 6. Import orphaned resource back into state
# EXAM NOTE: terraform import adds a resource to state.
#            It does NOT generate .tf configuration.
#            You must write the resource block manually first.
# ------------------------------------------------------------------
echo ""
echo "--- 6. terraform import (bring orphaned resource back) ---"
BUCKET_NAME=$(terraform output -raw state_demo_bucket_name 2>/dev/null || echo "bucket-name-here")
echo "Run: terraform import module.state_demo.aws_s3_bucket.demo ${BUCKET_NAME}"
echo "Note: You must have the resource block in your config before importing."

# ------------------------------------------------------------------
# 7. Refresh state (update state to match real infrastructure)
# EXAM NOTE: terraform refresh updates STATE FILE only.
#            It does NOT update .tf configuration files.
#            Configuration files are never modified by Terraform commands.
# ------------------------------------------------------------------
echo ""
echo "--- 7. terraform refresh (updates state, NOT config files) ---"
echo "Running: terraform refresh"
terraform refresh
echo "State updated to match real AWS resources."
echo ".tf files are unchanged - diff them to confirm:"
git diff --stat *.tf 2>/dev/null || echo "(not a git repo, but .tf files are unchanged)"

echo ""
echo "=================================================================="
echo "Practice complete. All wrong answers from Day 28 now reinforced."
echo "=================================================================="