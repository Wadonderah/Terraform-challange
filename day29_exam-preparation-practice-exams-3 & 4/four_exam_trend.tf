# =============================================================================
# four_exam_trend.tf
# Day 29: Terraform Associate Exam Prep — Practice Exams 3 & 4
# 30-Day Terraform Challenge | AWS AI/ML UserGroup Kenya | EveOps
#
# PURPOSE: Four-exam score trend, domain accuracy, readiness assessment,
# and Day 30 priority list — encoded as Terraform locals and outputs.
# Run: terraform output  to display all results.
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # FOUR-EXAM SCORE TREND
  # ---------------------------------------------------------------------------
  exam_scores = {
    exam_1_day28 = { score = 42, total = 57, percentage = 73.7, day = 28, notes = "Baseline — warm-up exam" }
    exam_2_day28 = { score = 45, total = 57, percentage = 78.9, day = 28, notes = "Warm-up effect, different source" }
    exam_3_day29 = { score = 46, total = 57, percentage = 80.7, day = 29, notes = "Sustained — state study helped" }
    exam_4_day29 = { score = 48, total = 57, percentage = 84.2, day = 29, notes = "Highest — lifecycle and workspace gaps closed" }
  }

  trend_analysis = {
    direction            = "Consistently upward across all four exams"
    lowest               = "73.7% (Exam 1)"
    highest              = "84.2% (Exam 4)"
    total_improvement    = "10.5 percentage points across four exams"
    all_above_threshold  = true
    passing_threshold    = "70% (40/57)"
    readiness_assessment = "READY — consistent upward trend, all exams above 70%, Day 30 exam confirmed"
  }

  # ---------------------------------------------------------------------------
  # FOUR-EXAM DOMAIN ACCURACY (combined across all 4 exams, 228 total questions)
  # ---------------------------------------------------------------------------
  domain_accuracy_all_four = {
    iac_concepts = {
      attempted = 16, correct = 13, accuracy = 81.3, status = "on_track"
    }
    terraform_purpose = {
      attempted = 12, correct = 11, accuracy = 91.7, status = "strong"
    }
    terraform_basics = {
      attempted = 20, correct = 17, accuracy = 85.0, status = "on_track"
    }
    terraform_cli = {
      attempted = 24, correct = 19, accuracy = 79.2, status = "on_track"
    }
    terraform_modules = {
      attempted = 16, correct = 11, accuracy = 68.8, status = "watch"
    }
    core_workflow = {
      attempted = 12, correct = 10, accuracy = 83.3, status = "on_track"
    }
    state_management = {
      attempted = 20, correct = 14, accuracy = 70.0, status = "borderline"
    }
    configuration = {
      attempted = 16, correct = 13, accuracy = 81.3, status = "on_track"
    }
    terraform_cloud = {
      attempted = 10, correct = 7,  accuracy = 70.0, status = "borderline"
    }
  }

  # Domains still needing attention (below 80%)
  watch_domains = {
    for domain, data in local.domain_accuracy_all_four :
    domain => data
    if data.accuracy < 80
  }

  # ---------------------------------------------------------------------------
  # PERSISTENT WRONG-ANSWER TOPICS (appeared in >1 exam)
  # ---------------------------------------------------------------------------
  persistent_gaps = [
    {
      topic        = "terraform state rm vs terraform destroy"
      appeared_in  = ["Exam 1", "Exam 2", "Exam 3"]
      my_explanation = "state rm orphans the resource — removes from state only, infra survives. destroy removes from state AND deletes the real resource. Never confuse these."
      resolved     = true
    },
    {
      topic        = "terraform import does not generate .tf config"
      appeared_in  = ["Exam 2", "Exam 4"]
      my_explanation = "terraform import adds an existing resource to state. You must ALREADY have the resource block written in your .tf file. After import, plan will show differences until your config exactly matches the real resource attributes."
      resolved     = true
    },
    {
      topic        = "State locking: apply only, not plan"
      appeared_in  = ["Exam 2", "Exam 4"]
      my_explanation = "State is locked during apply and state-modifying commands. Plan is read-only so it does not acquire a lock. Two operators can run plan simultaneously. Two operators cannot run apply simultaneously."
      resolved     = true
    },
    {
      topic        = "CLI workspaces vs Terraform Cloud workspaces"
      appeared_in  = ["Exam 3", "Exam 4"]
      my_explanation = "CLI workspaces: same config, multiple state files in the same backend. TF Cloud workspaces: completely separate entities with their own variables, runs, permissions, and state. They share the word workspace but are fundamentally different."
      resolved     = true
    },
    {
      topic        = "prevent_destroy does not block console deletion"
      appeared_in  = ["Exam 3", "Exam 4"]
      my_explanation = "prevent_destroy = true only blocks terraform destroy. If someone deletes the resource manually in the AWS console, it is gone. Terraform only controls what it controls."
      resolved     = true
    },
    {
      topic        = "~> operator: number of segments changes behaviour"
      appeared_in  = ["Exam 3", "Exam 4"]
      my_explanation = "~> 1.0 allows 1.x.x (minor increments). ~> 1.0.0 allows 1.0.x only (patch increments). The more segments you specify, the tighter the constraint. This is the pessimistic constraint operator."
      resolved     = true
    },
  ]

  # ---------------------------------------------------------------------------
  # TOP 5 PRIORITIES FOR DAY 30 FINAL REVIEW (in priority order)
  # ---------------------------------------------------------------------------
  day30_priorities = [
    {
      rank     = 1
      topic    = "terraform state rm vs terraform destroy vs terraform import"
      specific = "state rm = orphan (infra lives), destroy = kill (infra gone), import = adopt (no config generated)"
      why      = "Appeared in 3 of 4 exams. Highest frequency wrong answer across the challenge."
    },
    {
      rank     = 2
      topic    = "CLI workspace vs Terraform Cloud workspace behaviour"
      specific = "terraform.workspace string, default cannot be deleted, state locking is apply-only not plan"
      why      = "Appeared in exams 3 and 4. Concept distinction is frequently tested."
    },
    {
      rank     = 3
      topic    = "Version constraint operator edge cases"
      specific = "~> 1.0 (minor) vs ~> 1.0.0 (patch). >= 1.0, < 2.0.0 == ~> 1.0. No version = latest = dangerous."
      why      = "Consistent source of wrong answers. Easy to confuse under time pressure."
    },
    {
      rank     = 4
      topic    = "lifecycle meta-argument exact behaviour"
      specific = "prevent_destroy blocks terraform only, ignore_changes = all, create_before_destroy with unique names"
      why      = "prevent_destroy console-deletion trap caught me in exams 3 and 4."
    },
    {
      rank     = 5
      topic    = "Terraform workflow command order and prerequisites"
      specific = "validate requires init. fmt is always safe. refresh = apply -refresh-only in modern TF."
      why      = "Command ordering and prerequisites are frequently tested as scenario questions."
    },
  ]

  readiness = {
    rating           = "READY"
    evidence         = [
      "All four practice exams above 70% passing threshold",
      "Consistent upward trend: 73.7 -> 78.9 -> 80.7 -> 84.2",
      "All persistent wrong-answer gaps identified and addressed with hands-on exercises",
      "Exam 4 score of 84.2% provides comfortable margin above 70% threshold",
    ]
    exam_day_strategy = "20-minute focused review of Day30 priorities in the morning, then sit the exam"
  }
}

output "four_exam_trend" {
  description = "Four-exam score trend and trend analysis."
  value = {
    scores   = local.exam_scores
    analysis = local.trend_analysis
  }
}

output "readiness_assessment" {
  description = "Exam readiness assessment based on all four practice exams."
  value       = local.readiness
}

output "day30_priority_list" {
  description = "Top 5 topics to review on Day 30 in priority order."
  value       = local.day30_priorities
}

output "persistent_gaps_resolved" {
  description = "Persistent wrong-answer topics and their resolutions."
  value       = local.persistent_gaps
}

output "watch_domains" {
  description = "Domains still below 80% accuracy across four exams."
  value       = local.watch_domains
}