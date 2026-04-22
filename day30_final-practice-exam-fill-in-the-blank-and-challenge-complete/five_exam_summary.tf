# =============================================================================
# five_exam_summary.tf
# Day 30: Final Practice Exam, Fill-in-the-Blank, and Challenge Complete
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
# =============================================================================

locals {
  five_exam_scores = {
    exam_1 = { day = 28, score = 42, total = 57, pct = 73.7, notes = "Baseline warm-up exam" }
    exam_2 = { day = 28, score = 45, total = 57, pct = 78.9, notes = "Warm-up effect, different source" }
    exam_3 = { day = 29, score = 46, total = 57, pct = 80.7, notes = "State management study paid off" }
    exam_4 = { day = 29, score = 48, total = 57, pct = 84.2, notes = "Lifecycle and workspace gaps closed" }
    exam_5 = { day = 30, score = 50, total = 57, pct = 87.7, notes = "Final exam. Fill-in-the-blank precision study." }
  }

  total_questions_attempted = 5 * 57
  total_correct             = 42 + 45 + 46 + 48 + 50
  average_pct               = (73.7 + 78.9 + 80.7 + 84.2 + 87.7) / 5
  total_improvement         = 87.7 - 73.7

  readiness_assessment = {
    rating                  = "READY"
    all_above_threshold     = true
    passing_threshold_pct   = 70.0
    lowest_score            = "73.7% (Exam 1)"
    highest_score           = "87.7% (Exam 5)"
    average                 = "${local.average_pct}%"
    trend                   = "Consistent upward — no regression across any exam"
    improvement             = "+${local.total_improvement} percentage points"
    exam_day_strategy       = "Morning: 20-min review of top 5 priorities. Exam: 60 min, 57 questions, flag uncertain, complete pass first then revisit."
  }

  thirty_day_reflection = {
    what_changed = "Thinking about infrastructure changed from 'build and manage' to 'declare desired state and let Terraform converge reality toward it'. Configuration drift is no longer a mystery — it is a diff between desired and actual state. This framing makes every infrastructure problem smaller."

    most_proud_of = "State management understanding. Not the commands — the conceptual model. Understanding that terraform.tfstate is Terraform's belief about reality. That terraform state rm is an admission of ignorance, not a deletion. That terraform import is an adoption. The 30-second experiment of running state rm and seeing the AWS instance still running was worth more than any documentation."

    what_comes_next = "Import 40 manually created resources across 2 AWS accounts into Terraform. Establish proper S3+DynamoDB remote backend with GitHub Actions CI/CD. Then AZ-900 for multi-cloud coverage, then Terraform Cloud Foundation certification for enterprise features."

    message_to_community = "Wrong answers are the work. Run every command in your terminal — do not just read about it. The certification is not the point. The shift in how you think about systems is the durable output."
  }
}

output "five_exam_summary" {
  description = "Complete five-exam trajectory and readiness assessment."
  value = {
    scores               = local.five_exam_scores
    readiness_assessment = local.readiness_assessment
    total_improvement    = "+${local.total_improvement}%"
  }
}

output "thirty_day_reflection" {
  description = "30-day reflection answers as queryable output."
  value       = local.thirty_day_reflection
}