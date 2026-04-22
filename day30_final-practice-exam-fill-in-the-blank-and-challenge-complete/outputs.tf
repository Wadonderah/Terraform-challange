# =============================================================================
# outputs.tf
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# FILL-IN-THE-BLANK ANSWER 10:
# To apply a saved plan: terraform apply myplan.tfplan
# To save a plan:        terraform plan -out=myplan.tfplan
# This CI/CD pattern guarantees what was approved is exactly what runs.
# =============================================================================

output "challenge_bucket_names" {
  description = "Names of the S3 buckets created by for_each. Note the string keys."
  value       = { for k, v in aws_s3_bucket.challenge_buckets : k => v.bucket }
}

output "workspace" {
  description = "Current terraform.workspace value. FILL-IN-THE-BLANK Q3."
  value       = terraform.workspace
}

output "account_id" {
  description = "AWS account. From data source — read-only. FILL-IN-THE-BLANK Q8."
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "Deployment region."
  value       = data.aws_region.current.name
}

output "five_exam_summary" {
  description = "Five-exam score trajectory across the challenge."
  value = {
    exam_1 = "42/57 = 73.7% (Day 28 baseline)"
    exam_2 = "45/57 = 78.9% (Day 28)"
    exam_3 = "46/57 = 80.7% (Day 29)"
    exam_4 = "48/57 = 84.2% (Day 29)"
    exam_5 = "50/57 = 87.7% (Day 30 final)"
    total_improvement = "+14.0 percentage points"
    all_above_threshold = true
    average = "81.0%"
    readiness = "READY"
  }
}