# =============================================================
# Day 10 — count Example
# =============================================================
# count is the simplest loop. Use it when you need N identical
# copies of a resource and the list is STABLE (won't have items
# removed from the middle).
# =============================================================

# ── Simple count: create 3 identical IAM users ───────────────
resource "aws_iam_user" "simple" {
  count = 3
  name  = "terraform-user-${count.index}" # count.index: 0, 1, 2
}

# ── count with a list variable ────────────────────────────────
variable "user_names" {
  description = "List of IAM usernames"
  type        = list(string)
  default     = ["alice", "bob", "charlie"]
}

resource "aws_iam_user" "from_list" {
  count = length(var.user_names) # count.index maps to list position
  name  = var.user_names[count.index]
}

# ── THE PROBLEM: remove "alice" (index 0) ────────────────────
# If var.user_names becomes ["bob", "charlie"]:
#   index 0 → "bob"   (was "alice"  → Terraform DESTROYS alice, CREATES bob)
#   index 1 → "charlie" (was "bob"  → Terraform DESTROYS bob,  CREATES charlie)
#   index 2 → gone   (was "charlie" → Terraform DESTROYS charlie)
#
# Result: Terraform recreates ALL remaining users unnecessarily.
# This is the classic count-with-list footgun.
# ─────────────────────────────────────────────────────────────

# ── Referencing count resources in outputs ────────────────────
output "simple_user_arns" {
  description = "ARNs of the simple count users (accessed as a list)"
  value       = aws_iam_user.simple[*].arn # splat expression → list
}

output "from_list_user_arns" {
  description = "ARNs of list-driven count users"
  value       = [for u in aws_iam_user.from_list : u.arn]
}
